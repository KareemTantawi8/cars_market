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

  /// Get notifications
  Future<void> getNotifications({int page = 1}) async {
    if (page == 1) {
      emit(NotificationsLoading());
    }
    
    try {
      final response = await _repository.getNotifications(page: page);
      
      final data = response['data'] as List? ?? [];
      final currentPage = response['current_page'] as int? ?? 1;
      final lastPage = response['last_page'] as int? ?? 1;
      final total = response['total'] as int? ?? 0;
      
      if (page == 1) {
        emit(NotificationsLoaded(
          notifications: List<Map<String, dynamic>>.from(data),
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
        ));
      } else {
        // Append to existing list
        final currentState = state;
        if (currentState is NotificationsLoaded) {
          final allNotifications = [
            ...currentState.notifications,
            ...List<Map<String, dynamic>>.from(data),
          ];
          emit(NotificationsLoaded(
            notifications: allNotifications,
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
    try {
      await _repository.markAsRead(notificationId);
      emit(NotificationMarkedAsRead(notificationId));
      // Reload notifications to update read status
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        await getNotifications(page: currentState.currentPage);
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
      // Reload notifications
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        await getNotifications(page: 1);
      }
    } catch (e) {
      emit(NotificationsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

