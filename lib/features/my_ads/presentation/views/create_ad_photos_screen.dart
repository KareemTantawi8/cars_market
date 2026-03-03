import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../ads/presentation/cubit/create_ad_cubit.dart';

/// Represents a photo item: file path and whether it's the cover
class AdPhotoItem {
  final String path;
  final bool isCover;

  AdPhotoItem({required this.path, this.isCover = false});

  AdPhotoItem copyWith({String? path, bool? isCover}) {
    return AdPhotoItem(
      path: path ?? this.path,
      isCover: isCover ?? this.isCover,
    );
  }
}

/// Create Ad - Photo Upload (Step 4 of 4) - صور العربية
class CreateAdPhotosScreen extends StatefulWidget {
  final Map<String, dynamic>? formData;

  const CreateAdPhotosScreen({super.key, this.formData});

  @override
  State<CreateAdPhotosScreen> createState() => _CreateAdPhotosScreenState();
}

class _CreateAdPhotosScreenState extends State<CreateAdPhotosScreen> {
  static const int _maxPhotos = 5;

  final List<AdPhotoItem> _photos = [];
  final ImagePicker _picker = ImagePicker();

  /// Simulated upload state (in real app would be from API)
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Optionally simulate an ongoing upload for demo
    // _simulateUpload();
  }

  Future<void> _pickImages() async {
    if (_photos.length >= _maxPhotos) return;
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty || !mounted) return;
      setState(() {
        final startLength = _photos.length;
        final hadCover = _photos.any((p) => p.isCover);
        for (int i = 0; i < images.length && _photos.length < _maxPhotos; i++) {
          _photos.add(AdPhotoItem(
            path: images[i].path,
            isCover: !hadCover && startLength + i == 0,
          ));
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

  void _removePhoto(int index) {
    setState(() {
      final wasCover = _photos[index].isCover;
      _photos.removeAt(index);
      if (wasCover && _photos.isNotEmpty) {
        _photos[0] = _photos[0].copyWith(isCover: true);
      }
    });
  }

  void _setCover(int index) {
    setState(() {
      for (int i = 0; i < _photos.length; i++) {
        _photos[i] = _photos[i].copyWith(isCover: i == index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    _buildTitleSection(),
                    const SizedBox(height: 20),
                    _buildUploadZone(),
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      _buildUploadProgress(),
                    ],
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPhotosGrid(),
                    ],
                    const SizedBox(height: 20),
                    _buildQuickTip(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildPublishButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_forward, color: context.textPrimary),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'إنشاء إعلان',
        style: AppTextStyles.headingSmall,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'خطوة ٤ من ٤',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0,
                backgroundColor: context.surfaceBg,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'الصور',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صور السيارة',
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'أضف صوراً واضحة للسيارة من جميع الزوايا لتبيع أسرع. الصور الجيدة تزيد المشاهدات 5 مرات أو أكثر.',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadZone() {
    final canAdd = _photos.length < _maxPhotos;
    return InkWell(
      onTap: canAdd ? _pickImages : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: context.cardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAdd ? AppColors.primaryColor : AppColors.inputBorder,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo,
              size: 48,
              color: canAdd ? AppColors.primaryColor : context.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'أضف صور',
              style: AppTextStyles.bodyLarge.copyWith(
                color: canAdd ? context.textPrimary : context.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'مسموح بـ $_maxPhotos صور كحد أقصى',
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isUploading = false),
            child: Icon(Icons.close, color: context.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جاري الرفع...',
                  style: AppTextStyles.caption.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: context.surfaceBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_uploadProgress * 100).round()}%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        return _PhotoThumbnail(
          path: _photos[index].path,
          isCover: _photos[index].isCover,
          onRemove: () => _removePhoto(index),
          onSetCover: () => _setCover(index),
        );
      },
    );
  }

  Widget _buildQuickTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.primaryLight,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نصيحة عالسريع',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'صور لوحة القيادة والعداد والعجلات من قرب. العملاء يحبون رؤية هذه التفاصيل للاطمئنان.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    final formData = widget.formData;
    return BlocConsumer<CreateAdCubit, CreateAdState>(
      listener: (context, state) {
        if (state is CreateAdSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الإعلان وسيتم مراجعته قبل النشر'), backgroundColor: AppColors.success),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
        if (state is CreateAdError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreateAdSubmitting;
        final canSubmit = formData != null &&
            (formData['title'] as String?)?.trim().isNotEmpty == true &&
            (formData['brandId'] != null);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            text: 'نشر الإعلان',
            icon: Icons.arrow_forward,
            onPressed: (isSubmitting || !canSubmit) ? null : () => _submitAd(context, formData),
            isLoading: isSubmitting,
          ),
        );
      },
    );
  }

  void _submitAd(BuildContext context, Map<String, dynamic>? formData) {
    if (formData == null) return;
    final title = (formData['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) return;
    final imageFiles = _photos.map((p) => File(p.path)).toList();
    context.read<CreateAdCubit>().createAd(
          title: title,
          description: formData['description'] as String?,
          brandId: formData['brandId'] as int? ?? 0,
          modelId: formData['modelId'] as int?,
          yearId: formData['yearId'] as int?,
          condition: formData['condition'] as String? ?? 'used',
          price: formData['price'] as double?,
          isNegotiable: formData['isNegotiable'] as bool? ?? false,
          isPhoneVisible: formData['isPhoneVisible'] as bool? ?? true,
          imageFiles: imageFiles.isNotEmpty ? imageFiles : null,
        );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback onSetCover;

  const _PhotoThumbnail({
    required this.path,
    required this.isCover,
    required this.onRemove,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.antiAlias,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (isCover)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'صورة الغلاف',
                style: AppTextStyles.captionSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          Positioned(
            bottom: 8,
            left: 8,
            child: GestureDetector(
              onTap: onSetCover,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'جعل غلاف',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
