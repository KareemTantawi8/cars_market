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

  RegisterCubit({
    AuthRepository? authRepository,
    ApiClient? apiClient,
  })  : _authRepository = authRepository ?? AuthRepository(),
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
        emit(RegisterError(
            'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل'));
        return;
      }

      if (password != passwordConfirmation) {
        emit(const RegisterError('كلمة المرور وتأكيد كلمة المرور غير متطابقين'));
        return;
      }

      // Create request model
      final request = RegisterRequestModel(
        name: name.trim(),
        phone: phone.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        deviceName: deviceName,
      );

      // Call API
      final response = await _authRepository.registerAsUser(request);

      // Save token and user data
      await StorageService.saveAuthToken(response.token);
      await StorageService.saveUserType(response.user.type);
      await StorageService.saveUserId(response.user.id.toString());
      await StorageService.saveUserData(jsonEncode(response.user.toJson()));

      // Set auth token in API client for future requests
      _apiClient.setAuthToken(response.token);

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
    required String governorate,
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
        emit(RegisterError(
            'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل'));
        return;
      }

      if (password != passwordConfirmation) {
        emit(const RegisterError('كلمة المرور وتأكيد كلمة المرور غير متطابقين'));
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

      if (governorate.trim().isEmpty) {
        emit(const RegisterError('الرجاء إدخال المحافظة'));
        return;
      }

      // Create vendor request model
      final request = VendorRegisterRequestModel(
        name: name.trim(),
        phone: phone.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        companyName: companyName.trim(),
        governorate: governorate.trim(),
        deviceName: deviceName,
      );

      // Call API
      final response = await _authRepository.registerAsVendor(request);

      // Save token and user data
      await StorageService.saveAuthToken(response.token);
      await StorageService.saveUserType(response.user.type);
      await StorageService.saveUserId(response.user.id.toString());
      await StorageService.saveUserData(jsonEncode(response.user.toJson()));

      // Set auth token in API client for future requests
      _apiClient.setAuthToken(response.token);

      emit(RegisterSuccess(response));
    } catch (e) {
      emit(RegisterError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

