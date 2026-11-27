import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/chat_message.dart';
import 'package:ekride_frontend/models/conversation.dart';
import 'package:ekride_frontend/services/chat_provider.dart';
import 'package:ekride_frontend/services/chat_socket_service.dart';

class ChatRoomView extends StatefulWidget {
  final ConversationSummary conversation;
  final int currentUserId;
  final VoidCallback? onBack;

  const ChatRoomView({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.onBack,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant ChatRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chat = context.read<ChatProvider>();
    chat.sendMessage(text);
    _textController.clear();
    _focusNode.requestFocus();

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();
    final messages = chat.activeMessages;
    final isGroup = widget.conversation.isGroup;
    final title = widget.conversation.getTitle(widget.currentUserId);
    final rideCtx = widget.conversation.rideContext;

    // Scroll to bottom when message count increments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 80) {
        _scrollToBottom();
      }
    });

    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Column(
        children: [
          // 1. Pinned Ride Context Header
          _buildPinnedHeader(context, isDark, isGroup, title, rideCtx),

          // 2. Connection State Banner (if not connected)
          if (chat.connectionState != SocketConnectionState.connected)
            _buildConnectionBanner(chat.connectionState, isDark),

          // 3. Message Stream
          Expanded(
            child: chat.isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : messages.isEmpty
                    ? _buildEmptyChatPlaceholder(isDark, isGroup)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (ctx, idx) {
                          final msg = messages[idx];
                          final isMe = msg.senderId == widget.currentUserId;
                          return _buildMessageRow(msg, isMe, isDark, isGroup);
                        },
                      ),
          ),

          // 4. Input Bar
          _buildInputBar(context, isDark, chat),
        ],
      ),
    );
  }

  Widget _buildPinnedHeader(
    BuildContext context,
    bool isDark,
    bool isGroup,
    String title,
    RideContext? rideCtx,
  ) {
    final border = AppTheme.getBorder(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textMuted = AppTheme.getTextMuted(isDark);

    final activeRiders = widget.conversation.participants.where((p) => p.active).length;
    final totalSeats = rideCtx?.totalSeats ?? 4;
    final vehicleType = rideCtx?.vehicleType ?? 'CAR';

    String routeStr = 'Campus Corridor';
    if (rideCtx != null && rideCtx.originAddress.isNotEmpty) {
      final o = rideCtx.originAddress.split(',').first.trim();
      final d = rideCtx.destinationAddress.split(',').first.trim();
      routeStr = '$o → $d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(isDark),
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: textPrimary,
              onPressed: widget.onBack,
              tooltip: 'Back to Conversations',
            ),
          // Vehicle Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              vehicleType == 'BIKE'
                  ? Icons.two_wheeler_rounded
                  : vehicleType == 'CNG'
                      ? Icons.electric_rickshaw_rounded
                      : Icons.directions_car_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Title & Route Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGroup
                            ? AppTheme.violet.withValues(alpha: 0.18)
                            : AppTheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGroup ? '$activeRiders/$totalSeats Riders' : '1-on-1 Ride',
                        style: TextStyle(
                          color: isGroup ? AppTheme.violetLight : AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 12, color: AppTheme.primaryLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        routeStr,
                        style: TextStyle(color: textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rideCtx != null && rideCtx.estimatedTotalFare > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '৳${rideCtx.estimatedTotalFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Participants Button
          IconButton(
            tooltip: 'View Matched Students',
            icon: const Icon(Icons.people_outline_rounded, color: AppTheme.primaryLight, size: 21),
            onPressed: () => _showParticipantsDialog(context, isDark),
          ),
          // Safety Actions Menu
          PopupMenuButton<String>(
            tooltip: 'Safety & Actions',
            icon: const Icon(Icons.shield_outlined, color: AppTheme.accent, size: 21),
            onSelected: (val) {
              if (val == 'sos') {
                _showSosDialog(context, isDark);
              } else if (val == 'report') {
                _showReportDialog(context, isDark);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: Colors.orangeAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Report Student / Ride', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sos',
                child: Row(
                  children: [
                    Icon(Icons.emergency_outlined, color: AppTheme.danger, size: 18),
                    SizedBox(width: 8),
                    Text('Emergency SOS / Campus Help', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(SocketConnectionState state, bool isDark) {
    final isConnecting = state == SocketConnectionState.connecting;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: isConnecting
          ? Colors.amber.withValues(alpha: 0.15)
          : Colors.redAccent.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnecting ? Icons.sync_rounded : Icons.cloud_off_rounded,
            size: 14,
            color: isConnecting ? Colors.amber[800] : Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Text(
            isConnecting
                ? 'Connecting to real-time chat...'
                : 'Offline. Messages will be sent via REST fallback.',
            style: TextStyle(
              color: isConnecting ? Colors.amber[800] : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatPlaceholder(bool isDark, bool isGroup) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            Text(
              isGroup ? 'Ride Group Chat Created' : '1-on-1 Ride Chat Open',
              style: TextStyle(
                color: AppTheme.getTextPrimary(isDark),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coordinate your pickup landmark, exact timing, and split fare with your fellow verified university peers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage msg, bool isMe, bool isDark, bool isGroup) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.getSurfaceLight(true) : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorder(isDark)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  msg.content,
                  style: TextStyle(
                    color: AppTheme.getTextMuted(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeStr = DateFormat('h:mm a').format(msg.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.violet.withValues(alpha: 0.25),
              child: Text(
                msg.senderName?.isNotEmpty == true ? msg.senderName![0].toUpperCase() : 'U',
                style: const TextStyle(color: AppTheme.violetLight, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name and role in Group Chats
                if (!isMe && isGroup && msg.senderName != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName!,
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(isDark),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (msg.senderRole != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: msg.senderRole == 'PROVIDER'
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : AppTheme.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              msg.senderRole == 'PROVIDER' ? 'Driver/Host' : 'Rider',
                              style: TextStyle(
                                color: msg.senderRole == 'PROVIDER' ? AppTheme.primary : AppTheme.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                // Message Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppTheme.primaryGradient : null,
                    color: isMe ? null : AppTheme.getCardColor(isDark),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: AppTheme.getBorder(isDark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        msg.content,
                        style: TextStyle(
                          color: isMe ? Colors.black : AppTheme.getTextPrimary(isDark),
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMe ? Colors.black.withValues(alpha: 0.6) : AppTheme.getTextMuted(isDark),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, ChatProvider chat) {
    final border = AppTheme.getBorder(isDark);
    final cardBg = AppTheme.getCardColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter): _handleSend,
                },
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: TextStyle(color: AppTheme.getTextPrimary(isDark), fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Type message... (Enter to send, Shift+Enter for newline)',
                    hintStyle: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? AppTheme.getSurfaceLight(true) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: chat.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.black, size: 19),
                onPressed: chat.isSending ? null : _handleSend,
                tooltip: 'Send Message (Enter)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(isDark),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Verified Ride Participants', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.conversation.participants.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (ctx, i) {
                final p = widget.conversation.participants[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: p.role == 'PROVIDER'
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : AppTheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.role,
                          style: TextStyle(
                            color: p.role == 'PROVIDER' ? AppTheme.primary : AppTheme.secondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${p.university ?? "Campus Student"} • ID: ${p.studentId ?? "Verified"}\n${p.active ? "🟢 Active in ride" : "⚪ Left ride"}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSosDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: AppTheme.danger, size: 24),
            SizedBox(width: 8),
            Text('Campus Emergency SOS', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('If you feel unsafe or experience an emergency during your ride:'),
            SizedBox(height: 12),
            Text('📞 National Emergency: 999', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('📞 Dhaka University Proctorial Office: +880-2-9661900'),
            Text('📞 EkRide 24/7 Student Safety Hotline: +880-1700-000000'),
            SizedBox(height: 12),
            Text('Your live GPS and ride corridor have been securely logged.', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, bool isDark) {
    final reportCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: const Text('Report Student or Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the reason for your report. Our campus safety team will review the ride logs.'),
            const SizedBox(height: 10),
            TextField(
              controller: reportCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Inappropriate behavior, no-show, unsafe route...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted to EkRide Campus Safety Team.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Submit Report', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
