import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/app_logo.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../core/utils/extensions.dart';
import '../cubit/login_cubit.dart';
import '../views/register_screen.dart';

/// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<LoginCubit>();
      cubit.login(
        phone: _phoneController.text,
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // Show success toast
            CustomToast.showSuccess(
              context,
              state.response.message,
              duration: const Duration(seconds: 2),
            );
            // Navigate based on user type from API response
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                if (state.response.user.type == AppConstants.userTypeVendor) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.vendorDashboard,
                    (route) => false,
                  );
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                }
              }
            });
          } else if (state is LoginError) {
            // Show error toast
            CustomToast.showError(
              context,
              state.message,
              duration: const Duration(seconds: 4),
            );
          }
        },
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            final isLoading = state is LoginLoading;
            return Scaffold(
              backgroundColor: AppColors.backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Stack(
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              'تسجيل الدخول',
                              style: AppTextStyles.headingMedium,
                            ),
                            const SizedBox(height: 20),
                            // App Logo
                            const AppLogo(size: 80, withGlow: false),
                            const SizedBox(height: 20),
                            // Welcome Message
                            Text(
                              'مرحباً بك مجدداً',
                              style: AppTextStyles.headingLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Subtitle
                            Text(
                              'سجل دخولك للوصول إلى قطع الغيار والخدمات',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Phone Number Field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: AppTextStyles.input,
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف',
                                labelStyle: AppTextStyles.inputLabel,
                                hintText: '01X XXXX XXXX',
                                hintStyle: AppTextStyles.inputHint,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Icon(
                                    Icons.phone,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.inputBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorderFocused,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال رقم الهاتف';
                                }
                                if (value.length < 10) {
                                  return 'رقم الهاتف غير صحيح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(context),
                              style: AppTextStyles.input,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                labelStyle: AppTextStyles.inputLabel,
                                hintText: '••••••••',
                                hintStyle: AppTextStyles.inputHint,
                                prefixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.inputBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.inputBorderFocused,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال كلمة المرور';
                                }
                                if (value.length < AppConstants.minPasswordLength) {
                                  return 'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        // TODO: Navigate to forgot password screen
                                      },
                                child: Text(
                                  'هل نسيت كلمة المرور ؟',
                                  style: AppTextStyles.link,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Login Button
                            PrimaryButton(
                              text: 'تسجيل الدخول',
                              onPressed: isLoading ? null : () => _handleLogin(context),
                              isLoading: isLoading,
                            ),
                            const SizedBox(height: 16),
                            // Create Account Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ليس لديك حساب؟',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context.navigateTo(const RegisterScreen());
                                        },
                                  child: Text(
                                    'إنشاء حساب جديد',
                                    style: AppTextStyles.link,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Loading Overlay
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
