import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/segment_control.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/register_cubit.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../home/data/models/category_models.dart';

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
          CustomToast.showError(context, 'الرجاء اختيار المحافظة',
              duration: const Duration(seconds: 2));
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('اختر المحافظة', style: AppTextStyles.headingSmall),
            ),
            const Divider(color: AppColors.dividerColor),
            Expanded(
              child: state.governorates.isEmpty
                  ? Center(
                      child: Text('لا توجد بيانات',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: context.textSecondary)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: state.governorates.length,
                      itemBuilder: (context, index) {
                        final gov = state.governorates[index];
                        final isSelected = gov == _selectedGovernorate;
                        return ListTile(
                          title: Text(
                            gov.displayName,
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
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primaryColor)
                              : null,
                          onTap: () {
                            setState(() => _selectedGovernorate = gov);
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
        BlocProvider(create: (_) => RegisterCubit()),
        BlocProvider(create: (_) => CategoryCubit()..loadInitialData()),
      ],
      child: BlocListener<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            CustomToast.showSuccess(context, state.response.message,
                duration: const Duration(seconds: 2));
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (r) => false);
              }
            });
          }
        },
        child: BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, state) {
            final isLoading = state is RegisterLoading;
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
                    top: 100,
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
                    top: 250,
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
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          child: Column(
                            children: [
                              // App icon – rounded rectangle
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.55),
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
                                          size: 48, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dot indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (i) {
                                  final isCenter = i == 1;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
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
                              const SizedBox(height: 14),

                              Text(
                                'إنشاء حساب جديد ✨',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'انضم إلى أكبر سوق لقطع غيار السيارات في مصر',
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
                              padding:
                                  const EdgeInsets.fromLTRB(24, 20, 24, 40),
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
                                        margin:
                                            const EdgeInsets.only(bottom: 24),
                                        decoration: BoxDecoration(
                                          color: AppColors.inputBorder,
                                          borderRadius:
                                              BorderRadius.circular(2),
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
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('بيانات الحساب',
                                            style: AppTextStyles.headingSmall),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 14),
                                      child: Text(
                                        'اختر نوع حسابك وأدخل بياناتك',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                color: context.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // ── Account type segment ──────────────
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBackground,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppColors.inputBorder),
                                      ),
                                      child: SegmentControl<String>(
                                        segments: const [
                                          SegmentItem(
                                            value:
                                                AppConstants.userTypeCustomer,
                                            label: 'عميل',
                                          ),
                                          SegmentItem(
                                            value: AppConstants.userTypeVendor,
                                            label: 'تاجر',
                                          ),
                                        ],
                                        selectedValue: _selectedUserType,
                                        onChanged: (value) => setState(
                                            () => _selectedUserType = value),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Account type badge
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedUserType ==
                                                AppConstants.userTypeCustomer
                                            ? AppColors.primaryColor
                                                .withOpacity(0.1)
                                            : AppColors.accentColor
                                                .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedUserType ==
                                                  AppConstants.userTypeCustomer
                                              ? AppColors.primaryColor
                                                  .withOpacity(0.4)
                                              : AppColors.accentColor
                                                  .withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _selectedUserType ==
                                                    AppConstants.userTypeCustomer
                                                ? Icons.person_outline
                                                : Icons.store_outlined,
                                            size: 18,
                                            color: _selectedUserType ==
                                                    AppConstants.userTypeCustomer
                                                ? AppColors.primaryColor
                                                : AppColors.accentColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedUserType ==
                                                    AppConstants.userTypeCustomer
                                                ? 'أنت تسجل كعميل'
                                                : 'أنت تسجل كتاجر',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: _selectedUserType ==
                                                      AppConstants
                                                          .userTypeCustomer
                                                  ? AppColors.primaryColor
                                                  : AppColors.accentColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // ── Error banner ──────────────────────
                                    if (state is RegisterError) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.error.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors.error
                                                  .withOpacity(0.4)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: AppColors.error,
                                                size: 22),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                state.message,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                        color: AppColors.error,
                                                        fontWeight:
                                                            FontWeight.w500),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => context
                                                  .read<RegisterCubit>()
                                                  .clearError(),
                                              child: Icon(Icons.close,
                                                  color: AppColors.error,
                                                  size: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],

                                    // ── Full name ─────────────────────────
                                    _FieldLabel(label: 'الاسم الكامل'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _nameController,
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      style: AppTextStyles.input,
                                      decoration: _inputDeco(
                                        hint: 'أدخل اسمك بالكامل',
                                        icon: Icons.person_outline,
                                        context: context,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'الرجاء إدخال الاسم الكامل';
                                        }
                                        if (v.length < 3) {
                                          return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // ── Phone ─────────────────────────────
                                    _FieldLabel(label: 'رقم الموبايل'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      style: AppTextStyles.input,
                                      decoration: _inputDeco(
                                        hint: '01X XXXX XXXX',
                                        icon: Icons.phone_outlined,
                                        context: context,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'الرجاء إدخال رقم الموبايل';
                                        }
                                        if (v.length < 10) {
                                          return 'رقم الموبايل غير صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // ── Password ──────────────────────────
                                    _FieldLabel(label: 'كلمة المرور'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      style: AppTextStyles.input,
                                      decoration: _inputDeco(
                                        hint: '••••••••',
                                        icon: Icons.lock_outline,
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
                                    const SizedBox(height: 18),

                                    // ── Confirm password ──────────────────
                                    _FieldLabel(label: 'تأكيد كلمة المرور'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _passwordConfirmationController,
                                      obscureText:
                                          _obscurePasswordConfirmation,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          _handleRegister(context),
                                      style: AppTextStyles.input,
                                      decoration: _inputDeco(
                                        hint: '••••••••',
                                        icon: Icons.lock_outline,
                                        context: context,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePasswordConfirmation
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: context.textSecondary,
                                            size: 22,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePasswordConfirmation =
                                                  !_obscurePasswordConfirmation),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'الرجاء تأكيد كلمة المرور';
                                        }
                                        if (v != _passwordController.text) {
                                          return 'كلمة المرور وتأكيدها غير متطابقين';
                                        }
                                        return null;
                                      },
                                    ),

                                    // ── Vendor-only fields ────────────────
                                    if (_selectedUserType ==
                                        AppConstants.userTypeVendor) ...[
                                      const SizedBox(height: 18),
                                      _FieldLabel(label: 'اسم الشركة'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _companyNameController,
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.next,
                                        style: AppTextStyles.input,
                                        decoration: _inputDeco(
                                          hint: 'أدخل اسم الشركة',
                                          icon: Icons.store_outlined,
                                          context: context,
                                        ),
                                        validator: (v) {
                                          if (_selectedUserType ==
                                              AppConstants.userTypeVendor) {
                                            if (v == null || v.isEmpty) {
                                              return 'الرجاء إدخال اسم الشركة';
                                            }
                                            if (v.length < 2) {
                                              return 'اسم الشركة يجب أن يكون حرفين على الأقل';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),

                                      // Governorate picker
                                      BlocBuilder<CategoryCubit, CategoryState>(
                                        builder: (context, catState) {
                                          if (catState is CategoryLoading ||
                                              catState is CategoryInitial) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _FieldLabel(label: 'المحافظة'),
                                                const SizedBox(height: 8),
                                                const SizedBox(
                                                  height: 56,
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                ),
                                              ],
                                            );
                                          }
                                          if (catState is CategoryError) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _FieldLabel(label: 'المحافظة'),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: AppColors.error
                                                            .withOpacity(0.4)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          catState.message,
                                                          style: AppTextStyles
                                                              .bodySmall
                                                              .copyWith(
                                                                  color:
                                                                      AppColors
                                                                          .error),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      TextButton.icon(
                                                        onPressed: () => context
                                                            .read<
                                                                CategoryCubit>()
                                                            .loadInitialData(),
                                                        icon: const Icon(
                                                            Icons.refresh,
                                                            size: 16),
                                                        label: const Text(
                                                            'إعادة'),
                                                        style: TextButton
                                                            .styleFrom(
                                                                foregroundColor:
                                                                    AppColors
                                                                        .primaryColor),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          if (catState is CategoryLoaded) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _FieldLabel(label: 'المحافظة'),
                                                const SizedBox(height: 8),
                                                InkWell(
                                                  onTap: () =>
                                                      _showGovernorateSelectionDialog(
                                                          catState),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 16),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .inputBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      border: Border.all(
                                                        color: _selectedGovernorate ==
                                                                null
                                                            ? AppColors
                                                                .inputBorder
                                                            : AppColors
                                                                .inputBorderFocused,
                                                        width:
                                                            _selectedGovernorate ==
                                                                    null
                                                                ? 1
                                                                : 2,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.location_on_outlined,
                                                          color: _selectedGovernorate ==
                                                                  null
                                                              ? context
                                                                  .textSecondary
                                                              : AppColors
                                                                  .primaryColor,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            _selectedGovernorate
                                                                    ?.displayName ??
                                                                'اختر المحافظة',
                                                            style: _selectedGovernorate ==
                                                                    null
                                                                ? AppTextStyles
                                                                    .inputHint
                                                                : AppTextStyles
                                                                    .input,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.keyboard_arrow_down_rounded,
                                                          color: context
                                                              .textSecondary,
                                                        ),
                                                      ],
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

                                    const SizedBox(height: 32),

                                    // ── Register button ───────────────────
                                    PrimaryButton(
                                      text: 'إنشاء الحساب',
                                      onPressed: isLoading
                                          ? null
                                          : () => _handleRegister(context),
                                      isLoading: isLoading,
                                    ),
                                    const SizedBox(height: 24),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Divider(
                                                color: AppColors.inputBorder
                                                    .withOpacity(0.6))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text('أو',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color: context
                                                          .textSecondary)),
                                        ),
                                        Expanded(
                                            child: Divider(
                                                color: AppColors.inputBorder
                                                    .withOpacity(0.6))),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Login link
                                    Center(
                                      child: RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color: context.textSecondary),
                                          children: [
                                            const TextSpan(
                                                text: 'لديك حساب بالفعل؟  '),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: GestureDetector(
                                                onTap: isLoading
                                                    ? null
                                                    : () => context.pop(),
                                                child: Text(
                                                  'تسجيل الدخول',
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontWeight: FontWeight.w700,
                                                    decoration: TextDecoration
                                                        .underline,
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
                      child:
                          const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    required BuildContext context,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: Icon(icon, color: context.textSecondary, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.inputBorderFocused, width: 2),
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
