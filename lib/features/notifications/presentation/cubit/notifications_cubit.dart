import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notifications_repository.dart';

/// Notifications State
abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  NotificationsLoaded({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  }) : hasMore = currentPage < lastPage;

  /// Count of unread notifications (includes chat — same as bell + list).
  int get unreadCount =>
      notifications.where((n) => isNotificationUnread(n)).length;
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}

class NotificationMarkedAsRead extends NotificationsState {
  final int notificationId;
  NotificationMarkedAsRead(this.notificationId);
}

class AllNotificationsMarkedAsRead extends NotificationsState {}

/// Notifications Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit({NotificationsRepository? repository})
      : _repository = repository ?? NotificationsRepository(),
        super(NotificationsInitial());

  /// Get notifications (API: { data: [], meta: { current_page, per_page, total, last_page, from, to } })
  Future<void> getNotifications({int page = 1}) async {
    if (page == 1) {
      emit(NotificationsLoading());
    }

    try {
      final response = await _repository.getNotifications(page: page);

      final data = response['data'] as List? ?? [];
      final meta = response['meta'] is Map<String, dynamic> ? response['meta'] as Map<String, dynamic> : null;
      final currentPage = meta != null
          ? (meta['current_page'] as num?)?.toInt() ?? (response['current_page'] as num?)?.toInt() ?? 1
          : (response['current_page'] as num?)?.toInt() ?? 1;
      final lastPage = meta != null
          ? (meta['last_page'] as num?)?.toInt() ?? (response['last_page'] as num?)?.toInt() ?? 1
          : (response['last_page'] as num?)?.toInt() ?? 1;
      final total = meta != null
          ? (meta['total'] as num?)?.toInt() ?? (response['total'] as num?)?.toInt() ?? 0
          : (response['total'] as num?)?.toInt() ?? 0;

      final notificationsList = data.whereType<Map<String, dynamic>>().toList();

      if (page == 1) {
        emit(NotificationsLoaded(
          notifications: notificationsList,
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
        ));
      } else {
        final currentState = state;
        if (currentState is NotificationsLoaded) {
          emit(NotificationsLoaded(
            notifications: [...currentState.notifications, ...notificationsList],
            currentPage: currentPage,
            lastPage: lastPage,
            total: total,
          ));
        }
      }
    } catch (e) {
      emit(NotificationsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    final previousState = state;
    try {
      await _repository.markAsRead(notificationId);
      emit(NotificationMarkedAsRead(notificationId));
      if (previousState is NotificationsLoaded) {
        await getNotifications(page: previousState.currentPage);
      }
    } catch (e) {
      emit(NotificationsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      emit(AllNotificationsMarkedAsRead());
      await getNotifications(page: 1);
    } catch (e) {
      emit(NotificationsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

bool isNotificationUnread(Map<String, dynamic> n) {
  if (n['is_read'] == true) return false;
  if (n['read_at'] != null) return false;
  return true;
}

