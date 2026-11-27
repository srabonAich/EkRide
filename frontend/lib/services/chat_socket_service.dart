import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:ekride_frontend/models/chat_message.dart';

enum SocketConnectionState {
  connecting,
  connected,
  disconnected,
}

class ChatSocketService {
  final String wsUrl;
  StompClient? _client;
  String? _token;

  final _connectionStateController =
      StreamController<SocketConnectionState>.broadcast();
  Stream<SocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  SocketConnectionState _currentState = SocketConnectionState.disconnected;
  SocketConnectionState get currentState => _currentState;

  final Map<int, StompUnsubscribe> _activeSubscriptions = {};
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messages => _messageController.stream;

  ChatSocketService({this.wsUrl = 'ws://localhost:8080/ws'});

  void updateToken(String? token) {
    _token = token;
    if (_token != null && _token!.isNotEmpty) {
      connect();
    } else {
      disconnect();
    }
  }

  void connect() {
    if (_token == null || _token!.isEmpty) return;
    if (_currentState == SocketConnectionState.connected ||
        _currentState == SocketConnectionState.connecting) {
      return;
    }

    _setState(SocketConnectionState.connecting);

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        beforeConnect: () async {
          debugPrint('[STOMP] Connecting to $wsUrl with JWT');
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[STOMP] Error: $error');
          _setState(SocketConnectionState.disconnected);
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        onDisconnect: (frame) {
          debugPrint('[STOMP] Disconnected');
          _setState(SocketConnectionState.disconnected);
        },
        reconnectDelay: const Duration(seconds: 4),
      ),
    );

    _client?.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('[STOMP] Connected successfully');
    _setState(SocketConnectionState.connected);

    // Re-subscribe to any conversations that were active before reconnect
    final pendingConvIds = List<int>.from(_activeSubscriptions.keys);
    _activeSubscriptions.clear();
    for (final convId in pendingConvIds) {
      subscribeToConversation(convId);
    }
  }

  void _setState(SocketConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void subscribeToConversation(int conversationId) {
    if (_activeSubscriptions.containsKey(conversationId)) return;
    if (_client == null || !_client!.connected) {
      // Store intent so it subscribes upon connect
      _activeSubscriptions[conversationId] = ({unsubscribeHeaders}) {};
      return;
    }

    final unsubscribe = _client!.subscribe(
      destination: '/topic/conversations/$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            final message = ChatMessage.fromJson(data);
            _messageController.add(message);
          } catch (e) {
            debugPrint('[STOMP] Error parsing message: $e');
          }
        }
      },
    );
    _activeSubscriptions[conversationId] = unsubscribe;
  }

  void unsubscribeFromConversation(int conversationId) {
    final unSub = _activeSubscriptions.remove(conversationId);
    if (unSub != null) {
      try {
        unSub();
      } catch (_) {}
    }
  }

  bool sendMessage(int conversationId, String content) {
    if (_client == null || !_client!.connected) {
      return false;
    }

    _client!.send(
      destination: '/app/chat/$conversationId/send',
      body: jsonEncode({'content': content}),
    );
    return true;
  }

  void disconnect() {
    _activeSubscriptions.forEach((_, unsub) {
      try {
        unsub();
      } catch (_) {}
    });
    _activeSubscriptions.clear();
    _client?.deactivate();
    _client = null;
    _setState(SocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
  }
}
