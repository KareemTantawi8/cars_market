import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../home/data/models/category_models.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../data/models/vendor_profile_model.dart';

class VendorLocationEditScreen extends StatefulWidget {
  final VendorProfileModel profile;

  const VendorLocationEditScreen({
    super.key,
    required this.profile,
  });

  @override
  State<VendorLocationEditScreen> createState() =>
      _VendorLocationEditScreenState();
}

class _VendorLocationEditScreenState extends State<VendorLocationEditScreen> {
  final _addressController = TextEditingController();
  final _repo = UserProfileRepository();
  final _categoryRepo = CategoryRepository();
  List<GovernorateModel> _governorates = const [];
  int? _selectedGovernorateId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.profile.address ?? '';
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    try {
      final list = await _categoryRepo.getGovernorates();
      if (!mounted) return;
      final currentGov =
          (widget.profile.governorate ?? '').trim().toLowerCase();
      int? selected;
      if (currentGov.isNotEmpty) {
        for (final g in list) {
          if (g.displayName.trim().toLowerCase() == currentGov) {
            selected = g.id;
            break;
          }
        }
      }
      setState(() {
        _governorates = list;
        _selectedGovernorateId =
            selected ?? (list.isNotEmpty ? list.first.id : null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final gid = _selectedGovernorateId;
    final address = _addressController.text.trim();
    if (gid == null || gid <= 0) {
      CustomToast.showError(context, 'اختر المحافظة');
      return;
    }
    if (address.isEmpty) {
      CustomToast.showError(context, 'أدخل العنوان التفصيلي');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.updateProfileAddress(governorateId: gid, address: address);
      if (!mounted) return;
      CustomToast.showSuccess(context, 'تم تحديث العنوان بنجاح');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
            context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.subtleBg,
      appBar: AppBar(
        title: Text(
          'تعديل العنوان',
          style: AppTextStyles.headingSmall,
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _loadGovernorates();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المحافظة',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedGovernorateId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: _governorates.map((g) {
                              return DropdownMenuItem<int>(
                                value: g.id,
                                child: Text(g.displayName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGovernorateId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'العنوان التفصيلي',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'أدخل العنوان بالتفصيل هنا...',
                          filled: true,
                          fillColor: context.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'حفظ التعديلات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
