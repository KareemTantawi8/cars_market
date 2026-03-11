import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/segment_control.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../home/data/models/category_models.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/cubit/create_ad_cubit.dart';

/// Ad condition for edit form
enum AdCondition { newCondition, used }

/// Edit Ad screen - same fields as create, pre-filled from [ad]
class EditAdScreen extends StatefulWidget {
  final AdModel ad;

  const EditAdScreen({super.key, required this.ad});

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  AdCondition _condition = AdCondition.used;
  bool _isPriceNegotiable = false;
  bool _showPhoneToAll = true;
  bool _isActive = true;

  bool _brandSet = false;
  bool _modelSet = false;
  bool _yearSet = false;

  final List<String> _existingImagePaths = [];
  final List<File> _newImageFiles = [];
  static const int _maxNewPhotos = 5;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.ad.title;
    _descriptionController.text = widget.ad.description ?? '';
    _priceController.text = widget.ad.price != null && widget.ad.price! > 0
        ? widget.ad.price!.round().toString()
        : '';
    _condition = widget.ad.condition == 'new' ? AdCondition.newCondition : AdCondition.used;
    _isPriceNegotiable = widget.ad.isNegotiable;
    _showPhoneToAll = widget.ad.isPhoneVisible;
    _isActive = widget.ad.isActive;
    _existingImagePaths.addAll(widget.ad.images);
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

  void _syncCategoryFromAd(CategoryLoaded state) {
    if (!_brandSet && widget.ad.brandId != 0 && state.brands.isNotEmpty) {
      BrandModel? brand;
      for (final b in state.brands) {
        if (b.id == widget.ad.brandId) {
          brand = b;
          break;
        }
      }
      if (brand != null) {
        _brandSet = true;
        context.read<CategoryCubit>().selectBrand(brand);
      }
    }
    if (_brandSet &&
        state.selectedBrand != null &&
        state.models.isNotEmpty &&
        !_modelSet &&
        widget.ad.modelId != null) {
      CarModelModel? model;
      for (final m in state.models) {
        if (m.id == widget.ad.modelId) {
          model = m;
          break;
        }
      }
      if (model != null) {
        _modelSet = true;
        context.read<CategoryCubit>().selectModel(model);
      }
    }
    if (_modelSet &&
        state.selectedModel != null &&
        state.years.isNotEmpty &&
        !_yearSet &&
        widget.ad.yearId != null) {
      YearModel? year;
      for (final y in state.years) {
        if (y.id == widget.ad.yearId) {
          year = y;
          break;
        }
      }
      if (year != null) {
        _yearSet = true;
        context.read<CategoryCubit>().selectYear(year);
      }
    }
  }

  Future<void> _pickNewImages() async {
    if (_newImageFiles.length >= _maxNewPhotos) return;
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty || !mounted) return;
      setState(() {
        for (int i = 0; i < images.length && _newImageFiles.length < _maxNewPhotos; i++) {
          _newImageFiles.add(File(images[i].path));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل اختيار الصور: $e')),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImageFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: context.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'تعديل الإعلان',
          style: AppTextStyles.headingSmall,
        ),
        centerTitle: true,
      ),
      body: BlocListener<CategoryCubit, CategoryState>(
        listener: (context, state) {
          if (state is CategoryLoaded) _syncCategoryFromAd(state);
        },
        child: BlocConsumer<CreateAdCubit, CreateAdState>(
          listener: (context, state) {
            if (state is CreateAdSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تحديث الإعلان بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.of(context).pop(true);
            }
            if (state is CreateAdError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting = state is CreateAdSubmitting;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BlocBuilder<CategoryCubit, CategoryState>(
                    builder: (context, catState) {
                      if (catState is CategoryLoading && catState.loadingType == 'initial') {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (catState is CategoryLoaded) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('الماركة'),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: catState.selectedBrand?.displayName,
                              hint: 'اختر الماركة',
                              onTap: () => _showBrandSelection(catState),
                            ),
                            const SizedBox(height: 16),
                            _buildFieldLabel('الموديل'),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: catState.selectedModel?.displayName,
                              hint: 'اختر الموديل',
                              onTap: catState.selectedBrand != null
                                  ? () => _showModelSelection(catState)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildFieldLabel('السنة'),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: catState.selectedYear?.displayName,
                              hint: 'اختر السنة',
                              onTap: catState.selectedModel != null
                                  ? () => _showYearSelection(catState)
                                  : null,
                            ),
                          ],
                        );
                      }
                      if (catState is CategoryError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            catState.message,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
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
                    decoration: _inputDecoration(hint: 'عنوان الإعلان'),
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('الوصف'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    style: AppTextStyles.input,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      hint: 'الوصف...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('السعر (ج.م)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    style: AppTextStyles.input,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    decoration: _inputDecoration(hint: 'السعر'),
                  ),
                  const SizedBox(height: 16),
                  _buildToggle('السعر قابل للتفاوض', _isPriceNegotiable, (v) => setState(() => _isPriceNegotiable = v)),
                  const SizedBox(height: 8),
                  _buildToggle('إظهار رقم الهاتف', _showPhoneToAll, (v) => setState(() => _showPhoneToAll = v)),
                  const SizedBox(height: 8),
                  _buildToggle('الإعلان نشط', _isActive, (v) => setState(() => _isActive = v)),
                  const SizedBox(height: 24),
                  if (_existingImagePaths.isNotEmpty) ...[
                    _buildFieldLabel('الصور الحالية'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _existingImagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final path = _existingImagePaths[index];
                          final url = path.startsWith('http')
                              ? path
                              : '${AppConstants.storageBaseUrl}/$path';
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: context.surfaceBg,
                                child: Icon(Icons.broken_image, color: context.textHint),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_newImageFiles.length < _maxNewPhotos) ...[
                    _buildFieldLabel('إضافة صور جديدة (اختياري)'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickNewImages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: context.cardBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppColors.primaryColor, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'إضافة صور (${_newImageFiles.length}/$_maxNewPhotos)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_newImageFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImageFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _newImageFiles[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  left: -4,
                                  child: GestureDetector(
                                    onTap: () => _removeNewImage(index),
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.error,
                                      child: Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'حفظ التعديلات',
                    icon: Icons.save,
                    onPressed: isSubmitting ? null : _submit,
                    isLoading: isSubmitting,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: AppTextStyles.inputLabel);
  }

  Widget _buildDropdown({
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
                style: value != null && value.isNotEmpty ? AppTextStyles.input : AppTextStyles.inputHint,
              ),
            ),
            Icon(Icons.arrow_back_ios_new, size: 16, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, EdgeInsetsGeometry? contentPadding}) {
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

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان الإعلان'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final catState = context.read<CategoryCubit>().state;
    if (catState is! CategoryLoaded || catState.selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الماركة'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', ''));
    context.read<CreateAdCubit>().updateAd(
          widget.ad.id,
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          brandId: catState.selectedBrand!.id,
          modelId: catState.selectedModel?.id,
          yearId: catState.selectedYear?.id,
          condition: _condition == AdCondition.used ? 'used' : 'new',
          price: price,
          isNegotiable: _isPriceNegotiable,
          isPhoneVisible: _showPhoneToAll,
          isActive: _isActive,
          imageFiles: _newImageFiles.isEmpty ? null : _newImageFiles,
        );
  }

  void _showBrandSelection(CategoryLoaded state) {
    _showSelection<BrandModel>(
      title: 'اختر الماركة',
      items: state.brands,
      selected: state.selectedBrand,
      displayName: (b) => b.displayName,
      onSelect: (b) => context.read<CategoryCubit>().selectBrand(b),
    );
  }

  void _showModelSelection(CategoryLoaded state) {
    if (state.selectedBrand == null) return;
    _showSelection<CarModelModel>(
      title: 'اختر الموديل',
      items: state.models,
      selected: state.selectedModel,
      displayName: (m) => m.displayName,
      onSelect: (m) => context.read<CategoryCubit>().selectModel(m),
    );
  }

  void _showYearSelection(CategoryLoaded state) {
    if (state.selectedModel == null) return;
    _showSelection<YearModel>(
      title: 'اختر السنة',
      items: state.years,
      selected: state.selectedYear,
      displayName: (y) => y.displayName,
      onSelect: (y) => context.read<CategoryCubit>().selectYear(y),
    );
  }

  void _showSelection<T>({
    required String title,
    required List<T> items,
    required T? selected,
    required String Function(T) displayName,
    required Function(T) onSelect,
  }) {
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
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: AppTextStyles.headingSmall),
            ),
            const Divider(color: AppColors.dividerColor),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selected;
                  return ListTile(
                    title: Text(
                      displayName(item),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primaryColor : context.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryColor) : null,
                    onTap: () {
                      onSelect(item);
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
