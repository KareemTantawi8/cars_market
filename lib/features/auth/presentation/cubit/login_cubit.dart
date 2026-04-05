import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/login_response_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/push_notification_service.dart';

/// Login State
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LoginInitial extends LoginState {}

/// Loading state
class LoginLoading extends LoginState {}

/// Success state
class LoginSuccess extends LoginState {
  final LoginResponseModel response;

  const LoginSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Error state
class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Login Cubit
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;
  final ApiClient _apiClient;

  LoginCubit({
    AuthRepository? authRepository,
    ApiClient? apiClient,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _apiClient = apiClient ?? ApiClient(),
        super(LoginInitial());

  /// Login
  Future<void> login({
    required String phone,
    required String password,
    String deviceName = 'Mobile',
    String tokenType = 'mobile',
  }) async {
    emit(LoginLoading());

    try {
      // Validate inputs
      if (phone.trim().isEmpty) {
        emit(const LoginError('الرجاء إدخال رقم الموبايل'));
        return;
      }

      if (phone.trim().length < AppConstants.minPhoneLength) {
        emit(const LoginError('رقم الموبايل غير صحيح'));
        return;
      }

      if (password.isEmpty) {
        emit(const LoginError('الرجاء إدخال كلمة المرور'));
        return;
      }

      if (password.length < AppConstants.minPasswordLength) {
        emit(LoginError(
            'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل'));
        return;
      }

      // Get FCM token to send with login request
      final fcmToken = await PushNotificationService.instance.getToken();

      final request = LoginRequestModel(
        phone: phone.trim(),
        password: password,
        deviceName: deviceName,
        tokenType: tokenType,
        deviceToken: fcmToken,
      );

      final response = await _authRepository.login(request);

      await StorageService.saveAuthToken(response.token);
      await StorageService.saveUserType(response.user.type);
      await StorageService.saveUserId(response.user.id.toString());
      await StorageService.saveUserData(jsonEncode(response.user.toJson()));
      await StorageService.saveAbilities(response.abilities);

      _apiClient.setAuthToken(response.token);

      try {
        final userProfile = await _authRepository.getCurrentUser();
        await StorageService.saveUserData(jsonEncode(userProfile.toJson()));
        await StorageService.saveUserType(userProfile.type);
        await StorageService.saveUserId(userProfile.id.toString());
      } catch (_) {}

      unawaited(RealtimeService.instance.start());
      await PushNotificationService.instance.registerToken();
      unawaited(
        PushNotificationService.instance.establishNotificationSyncBaseline(),
      );

      emit(LoginSuccess(response));
    } catch (e) {
      emit(LoginError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

