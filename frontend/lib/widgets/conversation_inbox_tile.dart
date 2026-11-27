import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/conversation.dart';

class ConversationInboxTile extends StatelessWidget {
  final ConversationSummary conversation;
  final int currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  const ConversationInboxTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGroup = conversation.isGroup;
    final title = conversation.getTitle(currentUserId);
    final lastMsg = conversation.lastMessage;
    final unread = conversation.unreadCount;

    final bg = isSelected
        ? AppTheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    final border = isSelected
        ? AppTheme.primary.withValues(alpha: 0.4)
        : AppTheme.getBorder(isDark);

    String timeStr = '';
    final now = DateTime.now();
    final diff = now.difference(conversation.lastMessageAt);
    if (diff.inDays == 0) {
      timeStr = DateFormat('h:mm a').format(conversation.lastMessageAt.toLocal());
    } else if (diff.inDays < 7) {
      timeStr = DateFormat('E').format(conversation.lastMessageAt.toLocal());
    } else {
      timeStr = DateFormat('MMM d').format(conversation.lastMessageAt.toLocal());
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? border : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppTheme.getCardHover(isDark),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(isDark, isGroup),
              const SizedBox(width: 12),
              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: AppTheme.getTextPrimary(isDark),
                              fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: unread > 0 ? AppTheme.primary : AppTheme.getTextMuted(isDark),
                            fontSize: 11,
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Route & vehicle chips
                    if (conversation.rideContext != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _getVehicleBadgeColor(conversation.rideContext!.vehicleType).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              conversation.rideContext!.vehicleType,
                              style: TextStyle(
                                color: _getVehicleBadgeColor(conversation.rideContext!.vehicleType),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${conversation.rideContext!.originAddress.split(',').first.trim()} → ${conversation.rideContext!.destinationAddress.split(',').first.trim()}',
                              style: TextStyle(
                                color: AppTheme.getTextMuted(isDark),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Last message preview & unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg != null
                                ? (lastMsg.isSystem ? '🔔 ${lastMsg.content}' : (lastMsg.senderName != null ? '${lastMsg.senderName!.split(' ').first}: ${lastMsg.content}' : lastMsg.content))
                                : 'No messages yet',
                            style: TextStyle(
                              color: unread > 0 ? AppTheme.getTextPrimary(isDark) : AppTheme.getTextMuted(isDark),
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, bool isGroup) {
    if (isGroup) {
      final activeRiders = conversation.participants.where((p) => p.active).length;
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.violet.withValues(alpha: 0.3), AppTheme.primary.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.groups_rounded, color: AppTheme.primaryLight, size: 22),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeRiders',
                  style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final title = conversation.getTitle(currentUserId);
      final initial = title.isNotEmpty ? title[0].toUpperCase() : 'U';
      return Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppTheme.darkBackground : Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _getVehicleBadgeColor(String vehicleType) {
    switch (vehicleType) {
      case 'BIKE':
        return Colors.orangeAccent;
      case 'CNG':
        return AppTheme.primary;
      case 'CAR':
        return AppTheme.violetLight;
      default:
        return AppTheme.secondary;
    }
  }
}
