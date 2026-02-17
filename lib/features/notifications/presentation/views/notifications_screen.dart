import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
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

  String _getTimeOfDay(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final hour = date.hour;
      if (hour < 12) {
        return '${hour}:${date.minute.toString().padLeft(2, '0')} ص';
      } else {
        return '${hour - 12}:${date.minute.toString().padLeft(2, '0')} مساءً';
      }
    } catch (e) {
      return '';
    }
  }

  IconData _getNotificationIcon(String? type) {
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
    final notificationId = notification['id'] as int?;
    if (notificationId != null) {
      context.read<NotificationsCubit>().markAsRead(notificationId);
    }

    final type = notification['type']?.toString();
    final meta = notification['meta'] as Map<String, dynamic>?;

    if (type == 'search_request_accepted' || type == 'new_message') {
      final chatId = meta?['chat_id'];
      if (chatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId.toString(),
            'chatName': notification['title']?.toString() ?? '',
          },
        );
      }
    } else if (type == 'search_request_rejected') {
      // Navigate to My Ads or show details
      // TODO: Navigate to My Ads screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.check, color: AppColors.primaryColor),
          onPressed: () {
            context.read<NotificationsCubit>().markAllAsRead();
          },
        ),
        title: Text(
          'الإشعارات',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
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
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
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

            for (final notification in state.notifications) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new notification or action
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
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
    final isUnread = notification['read_at'] == null;
    final type = notification['type']?.toString();
    final title = notification['title']?.toString() ?? '';
    final body = notification['body']?.toString() ?? '';
    final createdAt = notification['created_at']?.toString();
    final vendor = notification['meta']?['vendor_name']?.toString();

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isUnread
              ? Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (vendor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      vendor,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(createdAt),
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textHint,
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

