import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        final notifications = notifProvider.notifications;
        final unreadCount = notifProvider.unreadCount;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.offWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title bar with "Mark all as read"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.darkInk,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.deepEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: () => notifProvider.markAllAsRead(),
                            child: Text(
                              'Mark read',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.teal : AppColors.deepEmerald,
                              ),
                            ),
                          ),
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(
                                  'Clear All Notifications',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                                ),
                                content: Text(
                                  'Are you sure you want to clear all notifications?',
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.errorRed,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Clear All'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await notifProvider.clearAllNotifications();
                            }
                          },
                          child: Text(
                            'Clear all',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(height: 20),

              // List of notifications or AppEmptyState (U1, F3)
              Expanded(
                child: notifProvider.isLoading && notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
                    : notifications.isEmpty
                        ? const AppEmptyState(
                            icon: AppIcons.notification,
                            title: 'You are all caught up',
                            message: 'No new notifications right now.',
                          )
                        : RefreshIndicator(
                            color: AppColors.deepEmerald,
                            onRefresh: () => notifProvider.fetchNotifications(),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: notifications.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final notif = notifications[index];
                                return _buildNotificationTile(
                                  context,
                                  notif,
                                  isDark,
                                  () => notifProvider.markAsRead(notif.id),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notif,
    bool isDark,
    VoidCallback onMarkRead,
  ) {
    IconData icon = AppIcons.info;
    Color iconColor = isDark ? AppColors.teal : AppColors.deepEmerald;

    if (notif.type == 'alert') {
      icon = AppIcons.warning;
      iconColor = AppColors.errorRed;
    } else if (notif.type == 'expense-add') {
      icon = AppIcons.receipt;
      iconColor = AppColors.mutedGold;
    }

    return InkWell(
      onTap: () {
        if (!notif.isRead) onMarkRead();
        // Navigation using metadata (F3)
        final groupId = notif.metadata['groupId']?.toString();
        if (groupId != null && groupId.isNotEmpty) {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : (isDark ? AppColors.darkCard.withValues(alpha: 0.8) : AppColors.lightEmerald.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? (isDark ? AppColors.darkBorder : AppColors.borderLight)
                : AppColors.deepEmerald.withValues(alpha: 0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkInk,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(notif.createdAt),
                        style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.grey[400] : AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[300] : AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
