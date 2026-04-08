import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/vendor_register_request_model.dart';
import '../../data/models/register_response_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/push_notification_service.dart';

/// Register State
abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RegisterInitial extends RegisterState {}

/// Loading state
class RegisterLoading extends RegisterState {}

/// Success state
class RegisterSuccess extends RegisterState {
  final RegisterResponseModel response;

  const RegisterSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Error state
class RegisterError extends RegisterState {
  final String message;

  const RegisterError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Register Cubit
class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _authRepository;
  final ApiClient _apiClient;

  RegisterCubit({AuthRepository? authRepository, ApiClient? apiClient})
    : _authRepository = authRepository ?? AuthRepository(),
      _apiClient = apiClient ?? ApiClient(),
      super(RegisterInitial());

  /// Register as user (customer)
  Future<void> registerAsUser({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String deviceName = 'Mobile',
  }) async {
    emit(RegisterLoading());

    try {
      // Validate inputs
      if (name.trim().isEmpty) {
        emit(const RegisterError('الرجاء إدخال الاسم الكامل'));
        return;
      }

      if (name.trim().length < 3) {
        emit(const RegisterError('الاسم يجب أن يكون 3 أحرف على الأقل'));
        return;
      }

      if (phone.trim().isEmpty) {
        emit(const RegisterError('الرجاء إدخال رقم الموبايل'));
        return;
      }

      if (phone.trim().length < AppConstants.minPhoneLength) {
        emit(const RegisterError('رقم الموبايل غير صحيح'));
        return;
      }

      if (password.isEmpty) {
        emit(const RegisterError('الرجاء إدخال كلمة المرور'));
        return;
      }

      if (password.length < AppConstants.minPasswordLength) {
        emit(
          RegisterError(
            'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل',
          ),
        );
        return;
      }

      if (password != passwordConfirmation) {
        emit(
          const RegisterError('كلمة المرور وتأكيد كلمة المرور غير متطابقين'),
        );
        return;
      }

      final fcmToken = await PushNotificationService.instance.getToken();

      final request = RegisterRequestModel(
        name: name.trim(),
        phone: phone.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        deviceName: deviceName,
        deviceToken: fcmToken,
      );

      final response = await _authRepository.registerAsUser(request);

      await StorageService.saveAuthToken(response.token);
      await StorageService.saveUserType(response.user.type);
      await StorageService.saveUserId(response.user.id.toString());
      await StorageService.saveUserData(jsonEncode(response.user.toJson()));
      await StorageService.saveAbilities(response.abilities);

      _apiClient.setAuthToken(response.token);

      unawaited(RealtimeService.instance.start());
      await PushNotificationService.instance.registerToken();
      unawaited(
        PushNotificationService.instance.establishNotificationSyncBaseline(),
      );

      emit(RegisterSuccess(response));
    } catch (e) {
      emit(RegisterError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Register as vendor
  Future<void> registerAsVendor({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String companyName,
    required int governorateId,
    String deviceName = 'Flutter App',
    String? address,
    List<int>? categoryIds,
  }) async {
    emit(RegisterLoading());

    try {
      // Validate inputs
      if (name.trim().isEmpty) {
        emit(const RegisterError('الرجاء إدخال الاسم الكامل'));
        return;
      }

      if (name.trim().length < 3) {
        emit(const RegisterError('الاسم يجب أن يكون 3 أحرف على الأقل'));
        return;
      }

      if (phone.trim().isEmpty) {
        emit(const RegisterError('الرجاء إدخال رقم الموبايل'));
        return;
      }

      if (phone.trim().length < AppConstants.minPhoneLength) {
        emit(const RegisterError('رقم الموبايل غير صحيح'));
        return;
      }

      if (password.isEmpty) {
        emit(const RegisterError('الرجاء إدخال كلمة المرور'));
        return;
      }

      if (password.length < AppConstants.minPasswordLength) {
        emit(
          RegisterError(
            'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل',
          ),
        );
        return;
      }

      if (password != passwordConfirmation) {
        emit(
          const RegisterError('كلمة المرور وتأكيد كلمة المرور غير متطابقين'),
        );
        return;
      }

      if (companyName.trim().isEmpty) {
        emit(const RegisterError('الرجاء إدخال اسم الشركة'));
        return;
      }

      if (companyName.trim().length < 2) {
        emit(const RegisterError('اسم الشركة يجب أن يكون حرفين على الأقل'));
        return;
      }

      if (governorateId <= 0) {
        emit(const RegisterError('الرجاء اختيار المحافظة'));
        return;
      }

      final request = VendorRegisterRequestModel(
        name: name.trim(),
        phone: phone.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        companyName: companyName.trim(),
        governorateId: governorateId,
        deviceName: deviceName,
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        categoryIds: categoryIds,
      );

      final response = await _authRepository.registerAsVendor(request);

      await StorageService.saveAuthToken(response.token);
      await StorageService.saveUserType(response.user.type);
      await StorageService.saveUserId(response.user.id.toString());
      await StorageService.saveUserData(jsonEncode(response.user.toJson()));
      await StorageService.saveAbilities(response.abilities);

      _apiClient.setAuthToken(response.token);

      unawaited(RealtimeService.instance.start());
      await PushNotificationService.instance.registerToken();
      unawaited(
        PushNotificationService.instance.establishNotificationSyncBaseline(),
      );

      emit(RegisterSuccess(response));
    } catch (e) {
      emit(RegisterError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Clear error state (e.g. when user dismisses the error banner)
  void clearError() {
    emit(RegisterInitial());
  }
}
