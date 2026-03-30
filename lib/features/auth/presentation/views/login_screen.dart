import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/extensions.dart';
import '../cubit/login_cubit.dart';
import '../views/register_screen.dart';

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
      context.read<LoginCubit>().login(
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
            CustomToast.showSuccess(context, state.response.message,
                duration: const Duration(seconds: 2));
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                if (state.response.user.type == AppConstants.userTypeVendor) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.vendorDashboard, (r) => false);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.home, (r) => false);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  PushNotificationService.tryNavigateToPendingChat();
                });
              }
            });
          } else if (state is LoginError) {
            CustomToast.showError(context, state.message,
                duration: const Duration(seconds: 4));
          }
        },
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            final isLoading = state is LoginLoading;
            return Scaffold(
              body: Stack(
                children: [
                  // ── Full-screen gradient background ───────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF060D1F),
                          Color(0xFF0D2248),
                          AppColors.primaryDark,
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // ── Decorative blobs ──────────────────────────────────────
                  Positioned(
                    top: -70,
                    right: -70,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: -90,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 260,
                    right: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),

                  // ── Main content ──────────────────────────────────────────
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                          child: Column(
                            children: [
                              // App icon – rounded rectangle (not circle)
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primaryColor.withOpacity(0.55),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(23),
                                  child: Image.asset(
                                    'assets/images/app_icon.jpeg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.primaryDark,
                                      child: const Icon(Icons.directions_car,
                                          size: 52, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Divider dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (i) {
                                  final isCenter = i == 1;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: isCenter ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: isCenter
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.35),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 18),

                              Text(
                                'مرحباً بك مجدداً 👋',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سجّل دخولك للوصول إلى قطع الغيار والخدمات',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.65),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // ── Form card ─────────────────────────────────────
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(36)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Handle bar
                                    Center(
                                      child: Container(
                                        width: 44,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 28),
                                        decoration: BoxDecoration(
                                          color: context.inputBorderColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),

                                    // Section title
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('تسجيل الدخول',
                                            style: AppTextStyles.headingSmall),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: Text(
                                        'أدخل بياناتك للمتابعة',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: context.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Phone field
                                    _FieldLabel(label: 'رقم الهاتف'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      style: AppTextStyles.input,
                                      decoration: _inputDecoration(
                                        hint: '01X XXXX XXXX',
                                        prefix: Icons.phone_outlined,
                                        context: context,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'الرجاء إدخال رقم الهاتف';
                                        }
                                        if (v.length < 10) {
                                          return 'رقم الهاتف غير صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Password field
                                    _FieldLabel(label: 'كلمة المرور'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          _handleLogin(context),
                                      style: AppTextStyles.input,
                                      decoration: _inputDecoration(
                                        hint: '••••••••',
                                        prefix: Icons.lock_outline,
                                        context: context,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: context.textSecondary,
                                            size: 22,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'الرجاء إدخال كلمة المرور';
                                        }
                                        if (v.length <
                                            AppConstants.minPasswordLength) {
                                          return 'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: isLoading ? null : () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'هل نسيت كلمة المرور ؟',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Login button
                                    PrimaryButton(
                                      text: 'تسجيل الدخول',
                                      onPressed: isLoading
                                          ? null
                                          : () => _handleLogin(context),
                                      isLoading: isLoading,
                                    ),
                                    const SizedBox(height: 28),

                                    // Divider with text
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                              color: AppColors.inputBorder
                                                  .withOpacity(0.6)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            'أو',
                                            style: AppTextStyles.caption.copyWith(
                                                color: context.textSecondary),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                              color: AppColors.inputBorder
                                                  .withOpacity(0.6)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Register link
                                    Center(
                                      child: RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.bodySmall.copyWith(
                                              color: context.textSecondary),
                                          children: [
                                            const TextSpan(
                                                text: 'ليس لديك حساب؟  '),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: GestureDetector(
                                                onTap: isLoading
                                                    ? null
                                                    : () => context.navigateTo(
                                                        const RegisterScreen()),
                                                child: Text(
                                                  'إنشاء حساب جديد',
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontWeight: FontWeight.w700,
                                                    decoration:
                                                        TextDecoration.underline,
                                                    decorationColor:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Loading overlay
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefix,
    required BuildContext context,
    Widget? suffix,
  }) {
    final borderColor = context.inputBorderColor;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint.copyWith(color: context.textHint),
      prefixIcon: Icon(prefix, color: context.textSecondary, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.inputBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(label, style: AppTextStyles.inputLabel),
      ],
    );
  }
}
