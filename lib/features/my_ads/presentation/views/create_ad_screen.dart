import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/segment_control.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../home/data/models/category_models.dart';

/// Ad condition: new or used
enum AdCondition {
  newCondition, // جديد
  used,         // مستعمل
}

/// Create Ad Form - Step 1 of 3 (إضافة إعلان)
class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  static const int _totalSteps = 3;
  final int _currentStep = 1;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  AdCondition _condition = AdCondition.used;
  bool _isPriceNegotiable = false;
  bool _showPhoneToAll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryCubit>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressSection(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainTitle(),
                    const SizedBox(height: 24),
                    _buildCarDetailsSection(),
                    const SizedBox(height: 24),
                    _buildAdDetailsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: TextButton(
          onPressed: () => Navigator.maybePop(context),
          child: Text(
            'إلغاء',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      leadingWidth: 80,
      title: Text(
        'Create Ad Form - Steps 1-2',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الخطوة $_currentStep من $_totalSteps',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentStep / _totalSteps,
              backgroundColor: AppColors.surfaceColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitle() {
    return Center(
      child: Text(
        'إضافة إعلان',
        style: AppTextStyles.headingMedium,
      ),
    );
  }

  Widget _buildCarDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('بيانات السيارة', 1),
        const SizedBox(height: 16),
        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading && state.loadingType == 'initial') {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state is CategoryLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('الماركة'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    value: state.selectedBrand?.displayName,
                    hint: 'اختر الماركة',
                    onTap: () => _showBrandSelection(state),
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('الموديل'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    value: state.selectedModel?.displayName,
                    hint: 'اختر الموديل',
                    onTap: state.selectedBrand != null
                        ? () => _showModelSelection(state)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('السنة'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    value: state.selectedYear?.displayName,
                    hint: 'اختر السنة',
                    onTap: state.selectedModel != null
                        ? () => _showYearSelection(state)
                        : null,
                  ),
                ],
              );
            }
            if (state is CategoryError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.message,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildAdDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('تفاصيل الإعلان', 2),
        const SizedBox(height: 16),
        _buildFieldLabel('الحالة'),
        const SizedBox(height: 8),
        SegmentControl<AdCondition>(
          segments: const [
            SegmentItem(value: AdCondition.newCondition, label: 'جديد'),
            SegmentItem(value: AdCondition.used, label: 'مستعمل'),
          ],
          selectedValue: _condition,
          onChanged: (v) => setState(() => _condition = v),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('عنوان الإعلان'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: AppTextStyles.input,
          decoration: _inputDecoration(
            hint: 'مثال: بي ام دبليو الفئة الثالثة بحالة ممتازة',
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('الوصف'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          style: AppTextStyles.input,
          maxLines: 4,
          decoration: _inputDecoration(
            hint: 'اكتب مواصفات السيارة والمميزات والعيوب إن وجدت....',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('السعر المطلوب'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          style: AppTextStyles.input,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          decoration: _inputDecoration(hint: '0').copyWith(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'ج.م',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
          ),
        ),
        const SizedBox(height: 16),
        _buildToggleRow(
          label: 'السعر قابل للتفاوض',
          value: _isPriceNegotiable,
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.success,
          onChanged: (v) => setState(() => _isPriceNegotiable = v),
        ),
        const SizedBox(height: 12),
        _buildToggleRow(
          label: 'إظهار رقم الهاتف للجميع',
          value: _showPhoneToAll,
          icon: Icons.phone_outlined,
          iconColor: AppColors.primaryColor,
          onChanged: (v) => setState(() => _showPhoneToAll = v),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int number) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.headingSmall,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.inputLabel,
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint,
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: (value != null && value.isNotEmpty)
                    ? AppTextStyles.input
                    : AppTextStyles.inputHint,
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PrimaryButton(
        text: 'التالي',
        icon: Icons.arrow_forward,
        onPressed: () {
          final title = _titleController.text.trim();
          if (title.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('أدخل عنوان الإعلان'), backgroundColor: AppColors.warning),
            );
            return;
          }
          final state = context.read<CategoryCubit>().state;
          if (state is! CategoryLoaded || state.selectedBrand == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('اختر الماركة'), backgroundColor: AppColors.warning),
            );
            return;
          }
          Navigator.pushNamed(context, AppRoutes.createAdPhotos, arguments: {
            'title': title,
            'description': _descriptionController.text.trim(),
            'brandId': state.selectedBrand!.id,
            'modelId': state.selectedModel?.id,
            'yearId': state.selectedYear?.id,
            'condition': _condition == AdCondition.used ? 'used' : 'new',
            'price': double.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0,
            'isNegotiable': _isPriceNegotiable,
            'isPhoneVisible': _showPhoneToAll,
          });
        },
      ),
    );
  }

  void _showBrandSelection(CategoryLoaded state) {
    _showSelectionBottomSheet<BrandModel>(
      title: 'اختر الماركة',
      items: state.brands,
      selectedItem: state.selectedBrand,
      getDisplayName: (b) => b.displayName,
      onSelected: (b) => context.read<CategoryCubit>().selectBrand(b),
    );
  }

  void _showModelSelection(CategoryLoaded state) {
    if (state.selectedBrand == null) return;
    _showSelectionBottomSheet<CarModelModel>(
      title: 'اختر الموديل',
      items: state.models,
      selectedItem: state.selectedModel,
      getDisplayName: (m) => m.displayName,
      onSelected: (m) => context.read<CategoryCubit>().selectModel(m),
    );
  }

  void _showYearSelection(CategoryLoaded state) {
    if (state.selectedModel == null) return;
    _showSelectionBottomSheet<YearModel>(
      title: 'اختر السنة',
      items: state.years,
      selectedItem: state.selectedYear,
      getDisplayName: (y) => y.displayName,
      onSelected: (y) => context.read<CategoryCubit>().selectYear(y),
    );
  }

  void _showSelectionBottomSheet<T>({
    required String title,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) getDisplayName,
    required Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: AppTextStyles.headingSmall),
            ),
            const Divider(color: AppColors.dividerColor),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد بيانات',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == selectedItem;
                        return ListTile(
                          title: Text(
                            getDisplayName(item),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.textPrimary,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primaryColor)
                              : null,
                          onTap: () {
                            onSelected(item);
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
}
