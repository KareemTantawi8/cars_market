import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Storage Service for local data persistence
class StorageService {
  static SharedPreferences? _prefs;

  /// Initialize storage service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  /// Save auth token
  static Future<bool> saveAuthToken(String token) async {
    return await prefs.setString(AppConstants.authTokenKey, token);
  }

  /// Get auth token
  static String? getAuthToken() {
    return prefs.getString(AppConstants.authTokenKey);
  }

  /// Remove auth token
  static Future<bool> removeAuthToken() async {
    return await prefs.remove(AppConstants.authTokenKey);
  }

  /// Save user type
  static Future<bool> saveUserType(String userType) async {
    return await prefs.setString(AppConstants.userTypeKey, userType);
  }

  /// Get user type
  static String? getUserType() {
    return prefs.getString(AppConstants.userTypeKey);
  }

  /// Save user ID
  static Future<bool> saveUserId(String userId) async {
    return await prefs.setString(AppConstants.userIdKey, userId);
  }

  /// Get user ID
  static String? getUserId() {
    return prefs.getString(AppConstants.userIdKey);
  }

  /// Save abilities (e.g. from login: ads.update, etc.)
  static Future<bool> saveAbilities(List<String> abilities) async {
    return await prefs.setStringList(AppConstants.abilitiesKey, abilities);
  }

  /// Get abilities (empty list if not set)
  static List<String> getAbilities() {
    return prefs.getStringList(AppConstants.abilitiesKey) ?? [];
  }

  /// Save user data
  static Future<bool> saveUserData(String userData) async {
    return await prefs.setString(AppConstants.userDataKey, userData);
  }

  /// Get user data
  static String? getUserData() {
    return prefs.getString(AppConstants.userDataKey);
  }

  /// Clear all data
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }

  /// Save FCM token
  static Future<bool> saveFcmToken(String token) async {
    return await prefs.setString(AppConstants.fcmTokenKey, token);
  }

  /// Get FCM token
  static String? getFcmToken() {
    return prefs.getString(AppConstants.fcmTokenKey);
  }

  /// Remove FCM token
  static Future<bool> removeFcmToken() async {
    return await prefs.remove(AppConstants.fcmTokenKey);
  }

  /// Save any string value
  static Future<bool> saveString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  /// Get any string value
  static String? getString(String key) {
    return prefs.getString(key);
  }

  /// Save any boolean value
  static Future<bool> saveBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  /// Get any boolean value
  static bool? getBool(String key) {
    return prefs.getBool(key);
  }

  /// Remove any key
  static Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  /// Vendor: watermark for GET /notifications sync (see PushNotificationService).
  static int getLastNotifiedNotificationApiId() {
    return prefs.getInt(AppConstants.lastNotifiedNotificationApiIdKey) ?? 0;
  }

  static Future<void> saveLastNotifiedNotificationApiId(int id) async {
    await prefs.setInt(AppConstants.lastNotifiedNotificationApiIdKey, id);
  }

  static bool isNotificationApiBaselineDone() {
    return prefs.getBool(AppConstants.notificationApiBaselineDoneKey) ?? false;
  }

  static Future<void> setNotificationApiBaselineDone() async {
    await prefs.setBool(AppConstants.notificationApiBaselineDoneKey, true);
  }
}

