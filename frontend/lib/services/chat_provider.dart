import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ekride_frontend/models/chat_message.dart';
import 'package:ekride_frontend/models/conversation.dart';
import 'package:ekride_frontend/services/api_service.dart';
import 'package:ekride_frontend/services/chat_socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService apiService;
  final ChatSocketService socketService;

  List<ConversationSummary> _conversations = [];
  ConversationSummary? _activeConversation;
  List<ChatMessage> _activeMessages = [];

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;

  StreamSubscription<ChatMessage>? _socketSubscription;
  StreamSubscription<SocketConnectionState>? _stateSubscription;
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;

  ChatProvider({
    required this.apiService,
    required this.socketService,
  }) {
    _stateSubscription = socketService.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _socketSubscription = socketService.messages.listen(_onIncomingMessage);
  }

  List<ConversationSummary> get conversations => _conversations;
  ConversationSummary? get activeConversation => _activeConversation;
  List<ChatMessage> get activeMessages => _activeMessages;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  SocketConnectionState get connectionState => _connectionState;

  int get totalUnreadCount {
    int sum = 0;
    for (final c in _conversations) {
      sum += c.unreadCount;
    }
    return sum;
  }

  void updateAuthToken(String? token) {
    socketService.updateToken(token);
    if (token != null && token.isNotEmpty) {
      loadConversations();
    } else {
      _conversations = [];
      _activeConversation = null;
      _activeMessages = [];
      notifyListeners();
    }
  }

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await apiService.getConversations();
      _isLoadingConversations = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(ConversationSummary summary) async {
    if (_activeConversation?.id == summary.id) return;

    if (_activeConversation != null) {
      socketService.unsubscribeFromConversation(_activeConversation!.id);
    }

    _activeConversation = summary;
    _activeMessages = [];
    _isLoadingMessages = true;
    notifyListeners();

    // Subscribe to STOMP destination
    socketService.subscribeToConversation(summary.id);

    try {
      final history = await apiService.getMessages(summary.id);
      _activeMessages = history;
      _isLoadingMessages = false;

      // Mark as read
      await markAsRead(summary.id);
      notifyListeners();
    } catch (e) {
      _isLoadingMessages = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> openConversationByRide(int rideId) async {
    _isLoadingConversations = true;
    notifyListeners();

    try {
      final summary = await apiService.getConversationByRide(rideId);
      final existingIndex = _conversations.indexWhere((c) => c.id == summary.id);
      if (existingIndex >= 0) {
        _conversations[existingIndex] = summary;
      } else {
        _conversations.insert(0, summary);
      }
      _isLoadingConversations = false;
      await selectConversation(summary);
    } catch (e) {
      _isLoadingConversations = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String content) async {
    if (_activeConversation == null) return false;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    _isSending = true;
    notifyListeners();

    final convId = _activeConversation!.id;

    // Try STOMP WebSocket first
    final sentViaSocket = socketService.sendMessage(convId, trimmed);

    if (!sentViaSocket) {
      // REST fallback
      try {
        final newMsg = await apiService.sendMessageRest(convId, trimmed);
        _addMessageIfNew(newMsg);
        _updateConversationLastMessage(convId, newMsg);
        _isSending = false;
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSending = false;
        notifyListeners();
        return false;
      }
    }

    _isSending = false;
    notifyListeners();
    return true;
  }

  Future<void> markAsRead(int conversationId) async {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx >= 0) {
      final old = _conversations[idx];
      _conversations[idx] = ConversationSummary(
        id: old.id,
        rideId: old.rideId,
        type: old.type,
        status: old.status,
        lastMessageAt: old.lastMessageAt,
        unreadCount: 0,
        lastMessage: old.lastMessage,
        rideContext: old.rideContext,
        participants: old.participants,
      );
    }
    try {
      await apiService.markAsRead(conversationId);
    } catch (_) {}
  }

  void _onIncomingMessage(ChatMessage message) {
    if (_activeConversation != null &&
        _activeConversation!.id == message.conversationId) {
      _addMessageIfNew(message);
      markAsRead(message.conversationId);
    }

    _updateConversationLastMessage(message.conversationId, message);
    notifyListeners();
  }

  void _addMessageIfNew(ChatMessage message) {
    if (!_activeMessages.any((m) => m.id == message.id)) {
      _activeMessages.add(message);
    }
  }

  void _updateConversationLastMessage(int convId, ChatMessage message) {
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx >= 0) {
      final old = _conversations.removeAt(idx);
      final isCurrentActive = _activeConversation?.id == convId;

      final updated = ConversationSummary(
        id: old.id,
        rideId: old.rideId,
        type: old.type,
        status: old.status,
        lastMessageAt: message.createdAt,
        unreadCount: isCurrentActive ? 0 : old.unreadCount + 1,
        lastMessage: message,
        rideContext: old.rideContext,
        participants: old.participants,
      );
      _conversations.insert(0, updated);
    } else {
      loadConversations();
    }
  }

  void clearActiveConversation() {
    if (_activeConversation != null) {
      socketService.unsubscribeFromConversation(_activeConversation!.id);
      _activeConversation = null;
      _activeMessages = [];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _stateSubscription?.cancel();
    socketService.dispose();
    super.dispose();
  }
}
