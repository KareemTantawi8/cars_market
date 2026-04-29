import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/notification_navigation.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../cubit/notifications_cubit.dart';

/// Notifications Screen
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().getNotifications();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<NotificationsCubit>().state;
      if (state is NotificationsLoaded && state.hasMore) {
        context.read<NotificationsCubit>().getNotifications(
              page: state.currentPage + 1,
            );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inHours < 1) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inDays < 1) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays == 1) {
        return 'أمس';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  IconData _getNotificationIcon(String? type) {
    final t = type ?? '';
    if (t == 'search_approved' ||
        t == 'search_request_accepted' ||
        t.contains('accept')) {
      return Icons.check_circle;
    }
    if (t == 'search_request_rejected' || t.contains('reject')) {
      return Icons.cancel;
    }
    if (t == 'new_message' || t.contains('message')) {
      return Icons.chat_bubble;
    }
    switch (type) {
      case 'search_request_accepted':
        return Icons.check_circle;
      case 'search_request_rejected':
        return Icons.cancel;
      case 'new_message':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    final t = type ?? '';
    if (t == 'search_approved' ||
        t == 'search_request_accepted' ||
        t.contains('accept')) {
      return AppColors.success;
    }
    if (t == 'search_request_rejected' || t.contains('reject')) {
      return AppColors.error;
    }
    if (t == 'new_message' || t.contains('message')) {
      return AppColors.primaryColor;
    }
    switch (type) {
      case 'search_request_accepted':
        return AppColors.success;
      case 'search_request_rejected':
        return AppColors.error;
      case 'new_message':
        return AppColors.primaryColor;
      default:
        return AppColors.info;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    unawaited(_handleNotificationTapAsync(notification));
  }

  Future<void> _handleNotificationTapAsync(Map<String, dynamic> notification) async {
    final notificationId = notificationRowId(notification);
    if (notificationId != null) {
      try {
        await context.read<NotificationsCubit>().markAsRead(notificationId);
      } catch (_) {}
    }

    if (!mounted) return;
    await navigateFromNotificationMap(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            context.read<NotificationsCubit>().markAllAsRead();
          },
        ),
        title: Text('الإشعارات', style: AppTextStyles.headingMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            CustomToast.showError(context, state.message);
          } else if (state is AllNotificationsMarkedAsRead) {
            CustomToast.showSuccess(context, 'تم تحديد جميع الإشعارات كمقروءة');
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsLoaded) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 72,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'لا توجد إشعارات',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أنت على اطلاع بكل جديد',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group notifications by date
            final today = DateTime.now();
            final yesterday = today.subtract(const Duration(days: 1));
            final todayNotifications = <Map<String, dynamic>>[];
            final yesterdayNotifications = <Map<String, dynamic>>[];
            final olderNotifications = <Map<String, dynamic>>[];

            for (final notification in notifications) {
              final createdAt = notification['created_at']?.toString();
              if (createdAt == null) continue;

              try {
                final date = DateTime.parse(createdAt);
                if (date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day) {
                  todayNotifications.add(notification);
                } else if (date.year == yesterday.year &&
                    date.month == yesterday.month &&
                    date.day == yesterday.day) {
                  yesterdayNotifications.add(notification);
                } else {
                  olderNotifications.add(notification);
                }
              } catch (e) {
                olderNotifications.add(notification);
              }
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsCubit>().getNotifications();
              },
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (todayNotifications.isNotEmpty) ...[
                    _buildSectionHeader('اليوم'),
                    ...todayNotifications.map((notification) =>
                        _buildNotificationCard(notification)),
                    const SizedBox(height: 16),
                  ],
                  if (yesterdayNotifications.isNotEmpty) ...[
                    _buildSectionHeader('الأمس'),
                    ...yesterdayNotifications.map((notification) =>
                        _buildNotificationCard(notification)),
                    const SizedBox(height: 16),
                  ],
                  if (olderNotifications.isNotEmpty) ...[
                    ...olderNotifications.map((notification) =>
                        _buildNotificationCard(notification)),
                  ],
                  if (state.hasMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'إعادة المحاولة',
                    onPressed: () {
                      context.read<NotificationsCubit>().getNotifications();
                    },
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = isNotificationUnread(notification);
    final type = notification['type']?.toString();
    final title = notification['title']?.toString() ?? '';
    final body = notification['body']?.toString() ?? '';
    final createdAt = notification['created_at']?.toString();
    final meta = parseNotificationMeta(notification['meta']);
    final vendor = meta?['vendor_name']?.toString() ??
        meta?['company_name']?.toString();
    final notificationId = notificationRowId(notification);

    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);

    return Dismissible(
      key: Key(notificationId?.toString() ?? notification.hashCode.toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.mark_email_read, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
           // delete logic if we had one
        } else {
           if (notificationId != null) {
              context.read<NotificationsCubit>().markAsRead(notificationId);
           }
        }
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? color.withOpacity(0.08)
                : context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? color.withOpacity(0.3)
                  : Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon with glowing background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(createdAt),
                          style: AppTextStyles.captionSmall.copyWith(
                            color: isUnread ? color : context.textHint,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (vendor != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 14, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            vendor,
                            style: AppTextStyles.caption.copyWith(
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isUnread ? context.textPrimary.withOpacity(0.9) : context.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6, left: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

