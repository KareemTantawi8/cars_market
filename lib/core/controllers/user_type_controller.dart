import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

/// User Type Controller - Manages current user type for development/testing
class UserTypeController extends ChangeNotifier {
  static final UserTypeController _instance = UserTypeController._internal();
  factory UserTypeController() => _instance;
  UserTypeController._internal();

  String? _currentUserType;

  /// Get current user type (loads from storage if not set)
  String? get currentUserType {
    if (_currentUserType == null) {
      _currentUserType = StorageService.getUserType();
    }
    return _currentUserType;
  }

  /// Check if current user is a customer
  bool get isCustomer => currentUserType == AppConstants.userTypeCustomer;

  /// Check if current user is a vendor
  bool get isVendor => currentUserType == AppConstants.userTypeVendor;

  /// Switch to customer user type
  Future<void> switchToCustomer() async {
    await _setUserType(AppConstants.userTypeCustomer);
  }

  /// Switch to vendor user type
  Future<void> switchToVendor() async {
    await _setUserType(AppConstants.userTypeVendor);
  }

  /// Toggle between customer and vendor
  Future<void> toggleUserType() async {
    if (isCustomer) {
      await switchToVendor();
    } else {
      await switchToCustomer();
    }
  }

  /// Set user type (public method for external use)
  Future<void> setUserType(String userType) async {
    await _setUserType(userType);
  }

  /// Set user type (private)
  Future<void> _setUserType(String userType) async {
    _currentUserType = userType;
    await StorageService.saveUserType(userType);
    // Save a mock token for testing
    await StorageService.saveAuthToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
    notifyListeners();
  }

  /// Clear user type (logout)
  Future<void> clear() async {
    _currentUserType = null;
    await StorageService.clearAll();
    notifyListeners();
  }

  /// Get user type display name
  String get userTypeDisplayName {
    switch (currentUserType) {
      case AppConstants.userTypeCustomer:
        return 'مستخدم';
      case AppConstants.userTypeVendor:
        return 'تاجر';
      default:
        return 'غير محدد';
    }
  }

  /// Initialize from storage
  Future<void> initialize() async {
    await StorageService.init();
    _currentUserType = StorageService.getUserType();
    notifyListeners();
  }
}

