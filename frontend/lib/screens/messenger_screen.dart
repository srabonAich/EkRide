import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/conversation.dart';
import 'package:ekride_frontend/services/auth_provider.dart';
import 'package:ekride_frontend/services/chat_provider.dart';
import 'package:ekride_frontend/widgets/conversation_inbox_tile.dart';
import 'package:ekride_frontend/widgets/chat_room_view.dart';

class MessengerScreen extends StatefulWidget {
  final int? initialRideId;

  const MessengerScreen({super.key, this.initialRideId});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      chat.loadConversations();
      if (widget.initialRideId != null) {
        chat.openConversationByRide(widget.initialRideId!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final currentUserId = auth.currentUser?.id ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    final filteredConversations = chat.conversations.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final title = c.getTitle(currentUserId).toLowerCase();
      final route = c.rideContext != null
          ? '${c.rideContext!.originAddress} ${c.rideContext!.destinationAddress}'.toLowerCase()
          : '';
      return title.contains(q) || route.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: AppTheme.getCardColor(isDark),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text(
              'EkRide Messenger',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Campus Verified',
                style: TextStyle(color: AppTheme.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Conversations',
            onPressed: () => chat.loadConversations(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? _buildWideSplitLayout(context, isDark, chat, currentUserId, filteredConversations)
          : _buildNarrowLayout(context, isDark, chat, currentUserId, filteredConversations),
    );
  }

  Widget _buildWideSplitLayout(
    BuildContext context,
    bool isDark,
    ChatProvider chat,
    int currentUserId,
    List<ConversationSummary> conversations,
  ) {
    final border = AppTheme.getBorder(isDark);
    final activeConv = chat.activeConversation;

    return Row(
      children: [
        // Left Pane: Inbox List (360px)
        SizedBox(
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(isDark),
              border: Border(right: BorderSide(color: border)),
            ),
            child: Column(
              children: [
                _buildSearchBox(isDark),
                Expanded(
                  child: _buildInboxList(context, isDark, chat, currentUserId, conversations),
                ),
              ],
            ),
          ),
        ),
        // Right Pane: Active Chat Room or Placeholder
        Expanded(
          child: activeConv != null
              ? ChatRoomView(
                  conversation: activeConv,
                  currentUserId: currentUserId,
                  onBack: null,
                )
              : _buildNoActiveConversationSelected(isDark),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    bool isDark,
    ChatProvider chat,
    int currentUserId,
    List<ConversationSummary> conversations,
  ) {
    final activeConv = chat.activeConversation;

    if (activeConv != null) {
      return ChatRoomView(
        conversation: activeConv,
        currentUserId: currentUserId,
        onBack: () => chat.clearActiveConversation(),
      );
    }

    return Column(
      children: [
        _buildSearchBox(isDark),
        Expanded(
          child: _buildInboxList(context, isDark, chat, currentUserId, conversations),
        ),
      ],
    );
  }

  Widget _buildSearchBox(bool isDark) {
    final border = AppTheme.getBorder(isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        style: TextStyle(color: AppTheme.getTextPrimary(isDark), fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search rides or peers...',
          hintStyle: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 12.5),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.getTextMuted(isDark)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          filled: true,
          fillColor: isDark ? AppTheme.getSurfaceLight(true) : Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
        ),
      ),
    );
  }

  Widget _buildInboxList(
    BuildContext context,
    bool isDark,
    ChatProvider chat,
    int currentUserId,
    List<ConversationSummary> conversations,
  ) {
    if (chat.isLoadingConversations && conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 40, color: AppTheme.getTextMuted(isDark)),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty ? 'No conversations match your search' : 'No active ride conversations',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'When you request or confirm a ride, your verified chat room appears here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 11.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: conversations.length,
      itemBuilder: (ctx, idx) {
        final c = conversations[idx];
        final isSelected = chat.activeConversation?.id == c.id;
        return ConversationInboxTile(
          conversation: c,
          currentUserId: currentUserId,
          isSelected: isSelected,
          onTap: () => chat.selectConversation(c),
        );
      },
    );
  }

  Widget _buildNoActiveConversationSelected(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'Select a Ride Conversation',
              style: TextStyle(
                color: AppTheme.getTextPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect in real-time with your verified campus peers for 1-on-1 and Group rides.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
