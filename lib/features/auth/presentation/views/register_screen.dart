import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/app_logo.dart';
import '../../../../shared/widgets/common/segment_control.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/register_cubit.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../home/data/models/category_models.dart';

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
  final _passwordConfirmationController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  String _selectedUserType = AppConstants.userTypeCustomer;
  GovernorateModel? _selectedGovernorate;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<RegisterCubit>();
      
      if (_selectedUserType == AppConstants.userTypeCustomer) {
        cubit.registerAsUser(
          name: _nameController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );
      } else {
        if (_selectedGovernorate == null) {
          CustomToast.showError(
            context,
            'الرجاء اختيار المحافظة',
            duration: const Duration(seconds: 2),
          );
          return;
        }
        cubit.registerAsVendor(
          name: _nameController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
          companyName: _companyNameController.text,
          governorateId: _selectedGovernorate!.id,
        );
      }
    }
  }

  void _showGovernorateSelectionDialog(CategoryLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'اختر المحافظة',
                style: AppTextStyles.headingSmall,
              ),
            ),
            const Divider(color: AppColors.dividerColor),
            // Items list
            Expanded(
              child: state.governorates.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد بيانات',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: state.governorates.length,
                      itemBuilder: (context, index) {
                        final governorate = state.governorates[index];
                        final isSelected = governorate == _selectedGovernorate;
                        return ListTile(
                          title: Text(
                            governorate.displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : context.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedGovernorate = governorate;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => RegisterCubit()),
        BlocProvider(create: (context) => CategoryCubit()..loadInitialData()),
      ],
      child: BlocListener<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            // Show success toast
            CustomToast.showSuccess(
              context,
              state.response.message,
              duration: const Duration(seconds: 2),
            );
            // Navigate to login screen after successful registration
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            });
          } else if (state is RegisterError) {
            // Show error toast
            CustomToast.showError(
              context,
              state.message,
              duration: const Duration(seconds: 4),
            );
          }
        },
        child: BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, state) {
            final isLoading = state is RegisterLoading;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   ),
              body: Stack(
                children: [
                  SafeArea(
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
                const SizedBox(height: 16),
                // App Logo
                const Center(
                  child: AppLogo(size: 70, withGlow: false),
                ),
                const SizedBox(height: 16),
                // Main Title
                Center(
                  child: Text(
                  'سجل معنا الآن',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'انضم إلى أكبر سوق لقطع غيار السيارات في مصر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 12),
                            // Selected Type Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedUserType == AppConstants.userTypeCustomer
                                    ? AppColors.primaryColor.withOpacity(0.1)
                                    : AppColors.buttonPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedUserType == AppConstants.userTypeCustomer
                                      ? AppColors.primaryColor.withOpacity(0.3)
                                      : AppColors.buttonPrimary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedUserType == AppConstants.userTypeCustomer
                                        ? Icons.person
                                        : Icons.store,
                                    size: 20,
                                    color: _selectedUserType == AppConstants.userTypeCustomer
                                        ? AppColors.primaryColor
                                        : AppColors.buttonPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedUserType == AppConstants.userTypeCustomer
                                        ? 'أنت تقوم بإنشاء حساب كعميل'
                                        : 'أنت تقوم بإنشاء حساب كتاجر',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: _selectedUserType == AppConstants.userTypeCustomer
                                          ? AppColors.primaryColor
                                          : AppColors.buttonPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
                          const SizedBox(height: 16),
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
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.phone,
                        color: context.textSecondary,
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
                          const SizedBox(height: 16),
                // Password Field
                Text(
                  'كلمة المرور',
                  style: AppTextStyles.inputLabel,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                  style: AppTextStyles.input,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTextStyles.inputHint,
                    prefixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: context.textSecondary,
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
                          const SizedBox(height: 16),
                          // Password Confirmation Field
                          Text(
                            'تأكيد كلمة المرور',
                            style: AppTextStyles.inputLabel,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordConfirmationController,
                            obscureText: _obscurePasswordConfirmation,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(context),
                            style: AppTextStyles.input,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: AppTextStyles.inputHint,
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _obscurePasswordConfirmation
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                            color: context.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePasswordConfirmation = !_obscurePasswordConfirmation;
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
                                return 'الرجاء تأكيد كلمة المرور';
                              }
                              if (value != _passwordController.text) {
                                return 'كلمة المرور وتأكيد كلمة المرور غير متطابقين';
                              }
                              return null;
                            },
                          ),
                          // Vendor-specific fields
                          if (_selectedUserType == AppConstants.userTypeVendor) ...[
                            const SizedBox(height: 16),
                            // Company Name Field
                            Text(
                              'اسم الشركة',
                              style: AppTextStyles.inputLabel,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _companyNameController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: AppTextStyles.input,
                              decoration: InputDecoration(
                                hintText: 'أدخل اسم الشركة',
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
                                if (_selectedUserType == AppConstants.userTypeVendor) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال اسم الشركة';
                                  }
                                  if (value.length < 2) {
                                    return 'اسم الشركة يجب أن يكون حرفين على الأقل';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Governorate Field (Dropdown)
                            if (_selectedUserType == AppConstants.userTypeVendor)
                              BlocBuilder<CategoryCubit, CategoryState>(
                                builder: (context, categoryState) {
                                  if (categoryState is CategoryLoading) {
                                    return const SizedBox(
                                      height: 60,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (categoryState is CategoryLoaded) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                            Text(
                              'المحافظة',
                              style: AppTextStyles.inputLabel,
                            ),
                            const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => _showGovernorateSelectionDialog(categoryState),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _selectedGovernorate == null
                                                    ? AppColors.inputBorder
                                                    : AppColors.inputBorderFocused,
                                                width: _selectedGovernorate == null ? 1 : 2,
                                  ),
                                ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _selectedGovernorate?.displayName ?? 'اختر المحافظة',
                                                    style: _selectedGovernorate == null
                                                        ? AppTextStyles.inputHint
                                                        : AppTextStyles.input,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: context.textSecondary,
                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_selectedGovernorate == null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4, right: 4),
                                            child: Text(
                                              'الرجاء اختيار المحافظة',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.error,
                                  ),
                                ),
                              ),
                                      ],
                                    );
                                  }

                                  return const SizedBox.shrink();
                              },
                            ),
                        ],
                        const SizedBox(height: 24),
                        // Create Account Button
                        PrimaryButton(
                          text: 'إنشاء الحساب',
                          onPressed: isLoading ? null : () => _handleRegister(context),
                          isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل ؟',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                        context.pop();
                      },
                      child: Text(
                        'تسجيل الدخول',
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
                // Loading Overlay
                  ), if (isLoading)
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
