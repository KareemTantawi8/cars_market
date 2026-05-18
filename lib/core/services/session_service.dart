import '../controllers/user_type_controller.dart';
import '../network/api_client.dart';
import 'push_notification_service.dart';
import 'realtime_service.dart';
import 'storage_service.dart';

/// Clears all local session state (storage, API token, realtime, FCM).
class SessionService {
  SessionService._();

  static Future<void> clearLocalSession() async {
    RealtimeService.instance.stop();
    await PushNotificationService.instance.unregisterToken();
    ApiClient().removeAuthToken();
    await StorageService.clearAll();
    UserTypeController().resetInMemory();
  }
}
