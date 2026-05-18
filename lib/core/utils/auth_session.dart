import '../services/storage_service.dart';

/// Helpers for checking whether the user has an active session.
class AuthSession {
  AuthSession._();

  static bool get isLoggedIn {
    final token = StorageService.getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
