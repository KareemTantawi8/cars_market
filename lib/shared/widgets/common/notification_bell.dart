import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/auth_session.dart';
import '../../../features/notifications/presentation/cubit/notifications_cubit.dart';

/// Notification bell icon that shows a red badge only when there are unread notifications.
class NotificationBell extends StatelessWidget {
  final Color iconColor;
  final Future<bool> Function()? onBeforeOpen;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.white,
    this.onBeforeOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (onBeforeOpen != null && AuthSession.isGuest) {
      return IconButton(
        icon: Icon(Icons.notifications_outlined, color: iconColor),
        onPressed: () async {
          await onBeforeOpen!();
        },
      );
    }

    return BlocProvider(
      create: (_) => NotificationsCubit()..getNotifications(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final unread = state is NotificationsLoaded ? state.unreadCount : 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: iconColor),
                onPressed: () async {
                  if (onBeforeOpen != null) {
                    final canOpen = await onBeforeOpen!();
                    if (!canOpen || !context.mounted) return;
                  }
                  final cubit = context.read<NotificationsCubit>();
                  await Navigator.pushNamed(context, AppRoutes.notifications);
                  // Refresh badge after returning — the notifications screen may
                  // have marked items as read in its own separate cubit instance.
                  if (context.mounted) cubit.getNotifications();
                },
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.notificationDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
