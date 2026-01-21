import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/controllers/user_type_controller.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/segment_control.dart';
import 'login_screen.dart';

/// Register Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedUserType = AppConstants.userTypeCustomer;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement register logic with Cubit
      // Save user type and token (simulate)
      final controller = UserTypeController();
      await controller.setUserType(_selectedUserType);
      
      // Navigate based on user type
      NavigationService.navigateAfterRegister(context, _selectedUserType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Title
                Center(
                  child: Text(
                    'إنشاء حساب',
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                const SizedBox(height: 32),
                // Main Title
                Text(
                  'سجل معنا الآن',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'انضم إلى أكبر سوق لقطع غيار السيارات في مصر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // User Type Selection
                SegmentControl<String>(
                  segments: const [
                    SegmentItem(
                      value: AppConstants.userTypeCustomer,
                      label: 'عميل',
                    ),
                    SegmentItem(
                      value: AppConstants.userTypeVendor,
                      label: 'تاجر',
                    ),
                  ],
                  selectedValue: _selectedUserType,
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value;
                    });
                  },
                ),
                const SizedBox(height: 32),
                // Full Name Field
                Text(
                  'الاسم الكامل',
                  style: AppTextStyles.inputLabel,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.input,
                  decoration: InputDecoration(
                    hintText: 'أدخل اسمك بالكامل',
                    hintStyle: AppTextStyles.inputHint,
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
                      return 'الرجاء إدخال الاسم الكامل';
                    }
                    if (value.length < 3) {
                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Mobile Number Field
                Text(
                  'رقم الموبايل',
                  style: AppTextStyles.inputLabel,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTextStyles.input,
                  decoration: InputDecoration(
                    hintText: '01X XXXX XXXX',
                    hintStyle: AppTextStyles.inputHint,
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
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
                      return 'الرجاء إدخال رقم الموبايل';
                    }
                    if (value.length < 10) {
                      return 'رقم الموبايل غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Password Field
                Text(
                  'كلمة المرور',
                  style: AppTextStyles.inputLabel,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  style: AppTextStyles.input,
                  decoration: InputDecoration(
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
                const SizedBox(height: 32),
                // Create Account Button
                PrimaryButton(
                  text: 'إنشاء الحساب',
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
                // Terms and Conditions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            const TextSpan(
                              text: 'بإنشاء حساب، أنت توافق على ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to terms and conditions
                                },
                                child: Text(
                                  'الشروط والأحكام',
                                  style: AppTextStyles.link.copyWith(
                                    fontSize: 14,
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
                const SizedBox(height: 16),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل ؟',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      child: Text(
                        'تسجيل الدخول',
                        style: AppTextStyles.link,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
