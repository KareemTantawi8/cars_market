import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/custom_toast.dart';

/// اختيار ماركات التاجر المدعومة ورفعها عبر PUT /user/profile (brand_ids).
class VendorSupportedBrandsScreen extends StatefulWidget {
  final List<int> initialBrandIds;

  const VendorSupportedBrandsScreen({
    super.key,
    this.initialBrandIds = const [],
  });

  @override
  State<VendorSupportedBrandsScreen> createState() =>
      _VendorSupportedBrandsScreenState();
}

class _VendorSupportedBrandsScreenState extends State<VendorSupportedBrandsScreen> {
  late List<int> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<int>.from(widget.initialBrandIds);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UserProfileRepository()
          .updateVendorSupportedBrandIds(_selectedIds);
      if (mounted) {
        CustomToast.showSuccess(context, 'تم حفظ الماركات');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'ماركاتي',
          style: AppTextStyles.headingSmall.copyWith(color: context.textPrimary),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading && state.loadingType == 'initial') {
            return const Center(child: LoadingIndicator());
          }
          if (state is CategoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          context.read<CategoryCubit>().loadInitialData(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! CategoryLoaded) {
            return const Center(child: LoadingIndicator());
          }
          final brands = state.brands;
          if (brands.isEmpty) {
            return Center(
              child: Text(
                'لا توجد ماركات',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondary),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    final isSelected = _selectedIds.contains(brand.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: _saving
                          ? null
                          : (val) {
                              setState(() {
                                if (val == true) {
                                  if (!_selectedIds.contains(brand.id)) {
                                    _selectedIds = [..._selectedIds, brand.id];
                                  }
                                } else {
                                  _selectedIds = _selectedIds
                                      .where((id) => id != brand.id)
                                      .toList();
                                }
                              });
                            },
                      title: Text(
                        brand.displayName,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: context.textPrimary),
                      ),
                      activeColor: AppColors.primaryColor,
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
