import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/vendor_profile_cubit.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../home/data/repositories/search_requests_repository.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../ads/data/repositories/ads_repository.dart';
import '../../../ads/data/models/ad_model.dart';

/// Vendor Profile Screen
class VendorProfileScreen extends StatelessWidget {
  final String vendorId;
  final String? vendorName;

  /// When true, [vendorId] is parsed as **user** id (e.g. from ad seller); profile is resolved via `GET /users/:id`.
  final bool bySellerUserId;

  const VendorProfileScreen({
    super.key,
    required this.vendorId,
    this.vendorName,
    this.bySellerUserId = false,
  });

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(vendorId) ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<VendorProfileCubit, VendorProfileState>(
          builder: (context, state) {
            if (state is VendorProfileLoading) {
              return const Center(child: LoadingIndicator());
            }

            if (state is VendorProfileError) {
              return Center(
                child: ErrorState(
                  message: state.message,
                  onRetry: () {
                    context.read<VendorProfileCubit>().fetchVendorProfile(
                          parsedId,
                          bySellerUserId: bySellerUserId,
                        );
                  },
                ),
              );
            }

            if (state is VendorProfileLoaded) {
              return _buildProfileContent(context, state.profile);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, VendorProfileModel profile) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: context.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: profile.isVendorAccount
                ? _buildVendorProfileBody(context, profile)
                : _buildCustomerProfileBody(context, profile),
          ),
        ),
      ],
    );
  }

  /// Vendor shop: brands, rating, address, verified, etc.
  Widget _buildVendorProfileBody(
      BuildContext context, VendorProfileModel profile) {
    final adsUserId = _resolveAdsOwnerUserId(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVendorInfoCard(context, profile),
        const SizedBox(height: 24),
        _buildVendorPreciseDetailsSection(context, profile),
        const SizedBox(height: 24),
        if (profile.supportedBrands.isNotEmpty)
          _buildSupportedBrandsSection(context, profile.supportedBrands),
        if (profile.supportedBrands.isNotEmpty) const SizedBox(height: 24),
        if (profile.availableServices.isNotEmpty)
          _buildAvailableServicesSection(context, profile.availableServices),
        if (profile.availableServices.isNotEmpty) const SizedBox(height: 24),
        if (_displayPhone(profile) != null) ...[
          _buildShopPhoneRow(context, _displayPhone(profile)!),
          const SizedBox(height: 16),
        ],
        _buildActionButtons(context, profile),
        const SizedBox(height: 24),
        if (profile.address != null && profile.address!.isNotEmpty)
          _buildTextAddressSection(context, profile),
        if (profile.address != null && profile.address!.isNotEmpty)
          const SizedBox(height: 24),
        _UserPublicAdsSection(userId: adsUserId),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Customer account: name, phone, ads. No vendor metrics or «تقييم التاجر».
  Widget _buildCustomerProfileBody(
      BuildContext context, VendorProfileModel profile) {
    final adsUserId = _resolveAdsOwnerUserId(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomerInfoCard(context, profile),
        const SizedBox(height: 24),
        _buildCustomerPreciseDetailsSection(context, profile),
        const SizedBox(height: 24),
        _UserPublicAdsSection(userId: adsUserId),
        const SizedBox(height: 24),
        _buildCustomerActionButtons(context, profile),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildVendorPreciseDetailsSection(
    BuildContext context,
    VendorProfileModel profile,
  ) {
    final brands = profile.supportedBrands
        .where((brand) => brand.trim().isNotEmpty)
        .join('، ');
    final address = _displayAddress(profile);
    final responseSpeed = _displayResponseSpeed(profile);

    return _buildDetailsCard(
      context,
      title: 'تفاصيل التاجر',
      rows: [
        _ProfileDetailItem(label: 'الاسم', value: profile.name),
        _ProfileDetailItem(
          label: 'الرقم',
          value: _displayPhone(profile) ?? 'غير متوفر',
          isLtrValue: true,
        ),
        _ProfileDetailItem(
          label: 'التقييم',
          value: '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount} تقييم)',
        ),
        _ProfileDetailItem(
          label: 'الماركات',
          value: brands.isNotEmpty ? brands : 'غير متوفر',
        ),
        _ProfileDetailItem(
          label: 'العنوان',
          value: address.isNotEmpty ? address : 'غير متوفر',
        ),
        _ProfileDetailItem(
          label: 'سرعة الرد',
          value: responseSpeed,
        ),
        _ProfileDetailItem(
          label: 'الحساب',
          value: profile.isVerified ? 'موثّق' : 'غير موثّق',
        ),
      ],
    );
  }

  Widget _buildCustomerPreciseDetailsSection(
    BuildContext context,
    VendorProfileModel profile,
  ) {
    return _buildDetailsCard(
      context,
      title: 'تفاصيل العميل',
      rows: [
        _ProfileDetailItem(label: 'الاسم', value: profile.name),
        _ProfileDetailItem(
          label: 'الرقم',
          value: _displayPhone(profile) ?? 'غير متوفر',
          isLtrValue: true,
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(
      BuildContext context, VendorProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: context.surfaceBg,
            backgroundImage:
                profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(profile.imageUrl!)
                    : null,
            child: profile.imageUrl == null || profile.imageUrl!.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppColors.primaryColor,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (profile.phone != null && profile.phone!.trim().isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: 18, color: context.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.phone!,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerActionButtons(
      BuildContext context, VendorProfileModel profile) {
    final myId = int.tryParse(StorageService.getUserId() ?? '');
    final otherId = profile.userAccountId ?? profile.id;
    final canChat =
        myId != null && otherId > 0 && myId != otherId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التواصل',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (canChat)
            _buildFilledActionButton(
              context,
              title: 'بدء محادثة',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryColor,
              onPressed: () => _openChatWithUser(context, profile),
            ),
          if (canChat) const SizedBox(height: 10),
          _buildFilledActionButton(
            context,
            title: 'واتساب',
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.success,
            onPressed: () => _openWhatsApp(profile.whatsapp ?? profile.phone),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithUser(
      BuildContext context, VendorProfileModel profile) async {
    final otherUserId = profile.userAccountId ?? profile.id;
    if (otherUserId <= 0) {
      if (context.mounted) {
        CustomToast.showError(context, 'لا يمكن تحديد حساب المستخدم للمحادثة.');
      }
      return;
    }
    try {
      final chatId =
          await ChatRepository().createChatWithUser(otherUserId);
      if (!context.mounted) return;
      if (chatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId.toString(),
            'chatName': profile.name,
            'peerPhone': profile.phone,
            'peerIsVerified': profile.isVerified,
            'peerAvatarUrl': profile.imageUrl,
          },
        );
      } else {
        CustomToast.showError(
          context,
          'لا يمكن بدء المحادثة الآن. جرّب واتساب أو أعد المحاولة لاحقاً.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'تعذّر فتح المحادثة. ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Widget _buildVendorInfoCard(BuildContext context, VendorProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.14),
                  AppColors.primaryColor.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'حساب تاجر',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (profile.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'موثّق',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CircleAvatar(
            radius: 42,
            backgroundColor: context.surfaceBg,
            backgroundImage:
                profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(profile.imageUrl!)
                    : null,
            child: profile.imageUrl == null || profile.imageUrl!.isEmpty
                ? Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: AppColors.primaryColor,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
          if (profile.description != null && profile.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.description!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.35,
                fontSize: 16,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: Icons.access_time_rounded,
                  value: profile.isOpen ? 'مفتوح' : 'مغلق',
                  subtitle: profile.openUntil ?? '',
                  color: profile.isOpen ? AppColors.success : AppColors.error,
                ),
              ),
              if (profile.responseTimeMinutes != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.speed_rounded,
                    value: '${profile.responseTimeMinutes} دقائق',
                    subtitle: 'سرعة الرد',
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: Icons.star_rounded,
                  value: profile.rating.toStringAsFixed(1),
                  subtitle: '${profile.ratingCount} تقييم',
                  color: AppColors.ratingStar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportedBrandsSection(BuildContext context, List<String> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الماركات المدعومة',
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: brands.take(4).map((brand) {
            final index = brands.indexOf(brand);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < brands.length - 1 ? 12 : 0),
                child: _buildBrandCard(context, brand),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandCard(BuildContext context, String brandName) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, color: AppColors.primaryColor, size: 30),
          const SizedBox(height: 8),
          Text(
            brandName,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableServicesSection(BuildContext context, List<String> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخدمات المتوفرة',
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: services.map((service) => _buildServiceChip(context, service)).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceChip(BuildContext context, String serviceName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Text(
        serviceName,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildShopPhoneRow(BuildContext context, String shopPhone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رقم المحل',
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondary),
                ),
                Text(
                  shopPhone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:$shopPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'اتصال',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context, {
    required String title,
    required List<_ProfileDetailItem> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Column(
              children: [
                _buildDetailRow(
                  context,
                  label: row.label,
                  value: row.value,
                  isLtrValue: row.isLtrValue,
                ),
                if (index < rows.length - 1)
                  Divider(
                    color: context.inputBorderColor.withOpacity(0.45),
                    height: 18,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isLtrValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.start,
            textDirection: isLtrValue ? TextDirection.ltr : TextDirection.rtl,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  int _resolveAdsOwnerUserId(VendorProfileModel profile) {
    final accountId = profile.userAccountId;
    if (accountId != null && accountId > 0) return accountId;

    final requestedId = int.tryParse(vendorId);
    if (bySellerUserId && requestedId != null && requestedId > 0) {
      return requestedId;
    }
    return profile.id;
  }

  String? _displayPhone(VendorProfileModel profile) {
    final candidate = profile.shopPhone?.trim().isNotEmpty == true
        ? profile.shopPhone
        : profile.phone;
    final phone = candidate?.trim();
    if (phone == null || phone.isEmpty) return null;
    return phone;
  }

  String _displayAddress(VendorProfileModel profile) {
    final parts = <String>[];
    final governorate = profile.governorate?.trim();
    final address = profile.address?.trim();
    if (governorate != null && governorate.isNotEmpty) parts.add(governorate);
    if (address != null && address.isNotEmpty) parts.add(address);
    return parts.join(' - ');
  }

  String _displayResponseSpeed(VendorProfileModel profile) {
    final human = profile.responseTimeHuman?.trim();
    if (human != null && human.isNotEmpty) return human;
    final minutes = profile.responseTimeMinutes;
    if (minutes != null && minutes > 0) return '$minutes دقيقة';
    return 'غير متوفر';
  }

  Widget _buildActionButtons(BuildContext context, VendorProfileModel profile) {
    final userType = StorageService.getUserType();
    final isCustomer = userType != AppConstants.userTypeVendor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التواصل مع التاجر',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          if (isCustomer) ...[
            _buildFilledActionButton(
              context,
              title: 'بدء محادثة',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryColor,
              onPressed: () => _openChatWithVendor(context, profile),
            ),
            const SizedBox(height: 10),
          ],
          _buildFilledActionButton(
            context,
            title: 'واتساب',
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.success,
            onPressed: () => _openWhatsApp(profile.whatsapp ?? profile.phone),
          ),
          if (isCustomer) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(context, profile),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: Text(
                  'تقييم التاجر',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.ratingStar,
                  side: BorderSide(
                    color: AppColors.ratingStar.withOpacity(0.75),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilledActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAddressSection(BuildContext context, VendorProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('العنوان', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.inputBorderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.governorate != null && profile.governorate!.isNotEmpty)
                      Text(profile.governorate!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    if (profile.address != null && profile.address!.isNotEmpty)
                      Text(profile.address!, style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary)),
                  ],
                ),
              ),
              if (profile.latitude != null && profile.longitude != null)
                GestureDetector(
                  onTap: () => _openGoogleMaps(profile.latitude, profile.longitude, profile.address),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('الاتجاهات', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openChatWithVendor(
      BuildContext context, VendorProfileModel profile) async {
    final otherUserId = profile.userAccountId;
    if (otherUserId == null || otherUserId <= 0) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'لا يمكن تحديد حساب هذا التاجر للمحادثة. يمكنك التواصل عبر واتساب.',
        );
      }
      return;
    }
    try {
      final chatId = await ChatRepository().openChatWithAdSeller(
        sellerUserId: otherUserId,
        sellerVendorRecordId: profile.id,
      );

      if (!context.mounted) return;

      if (chatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId.toString(),
            'chatName': profile.name,
            'peerPhone': profile.phone ?? profile.shopPhone,
            'peerIsVerified': profile.isVerified,
            'peerAvatarUrl': profile.imageUrl,
          },
        );
      } else {
        CustomToast.showError(
          context,
          'لا يمكن بدء المحادثة الآن. جرّب واتساب أو أعد المحاولة لاحقاً.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'تعذّر فتح المحادثة. ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _openWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return;
    }

    // Remove any non-digit characters and ensure it starts with country code
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanNumber.startsWith('20')) {
      cleanNumber = '20$cleanNumber';
    }

    final url = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGoogleMaps(double? lat, double? lng, String? address) async {
    if (lat == null && lng == null && (address == null || address.isEmpty)) return;

    // Try native app URI first (opens Maps directly in directions mode),
    // then fall back to universal web URL.
    final List<Uri> candidates = [];

    if (lat != null && lng != null) {
      if (Platform.isAndroid) {
        // geo: intent opens any maps app; google.navigation forces Google Maps + directions
        candidates.add(Uri.parse('google.navigation:q=$lat,$lng&mode=d'));
        candidates.add(Uri.parse('geo:$lat,$lng?q=$lat,$lng'));
      } else if (Platform.isIOS) {
        candidates.add(Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'));
        // Apple Maps fallback
        candidates.add(Uri.parse('maps://?daddr=$lat,$lng&dirflg=d'));
      }
      // Universal web fallback (always last)
      candidates.add(Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lng',
        'travelmode': 'driving',
      }));
    } else if (address != null && address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      if (Platform.isAndroid) {
        candidates.add(Uri.parse('google.navigation:q=$encoded&mode=d'));
      } else if (Platform.isIOS) {
        candidates.add(Uri.parse('comgooglemaps://?daddr=$encoded&directionsmode=driving'));
        candidates.add(Uri.parse('maps://?daddr=$encoded&dirflg=d'));
      }
      candidates.add(Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': address,
        'travelmode': 'driving',
      }));
    }

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }

  Future<void> _showRatingDialog(
      BuildContext context, VendorProfileModel profile) async {
    // Fetch customer's search requests, find one for this vendor
    List<Map<String, dynamic>> requests;
    try {
      requests = await SearchRequestsRepository().getMySearchRequests();
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(context, 'تعذّر تحميل الطلبات، حاول مرة أخرى.');
      }
      return;
    }

    // Find accepted/unrated request for this vendor
    final target = requests.firstWhere(
      (r) {
        final status = r['status'] as String?;
        final hasRating = r['rating'] != null;
        final vendorId = (r['vendor'] as Map?)?['id'] ??
            (r['accepted_by'] as Map?)?['id'];
        final vendorUserId = vendorId is num ? vendorId.toInt() : int.tryParse(vendorId?.toString() ?? '');
        return (status == 'accepted' || status == 'completed') &&
            !hasRating &&
            vendorUserId == profile.id;
      },
      orElse: () => {},
    );

    if (target.isEmpty) {
      if (context.mounted) {
        CustomToast.showInfo(
            context, 'لا توجد طلبات مكتملة مع هذا التاجر للتقييم.');
      }
      return;
    }

    if (!context.mounted) return;

    int selectedRating = 0;
    final reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('تقييم ${profile.name}',
              style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.ratingStar,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أضف تعليقاً (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      try {
                        await SearchRequestsRepository().rateSearchRequest(
                          requestId: target['id'] as int,
                          rating: selectedRating,
                          review: reviewController.text.trim().isEmpty
                              ? null
                              : reviewController.text.trim(),
                        );
                        if (context.mounted) {
                          CustomToast.showSuccess(
                              context, 'تم إرسال التقييم بنجاح!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomToast.showError(
                              context, 'تعذّر إرسال التقييم: $e');
                        }
                      } finally {
                        reviewController.dispose();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /users/:id/ads — public listings on profile visit
// ─────────────────────────────────────────────────────────────────────────────

class _UserPublicAdsSection extends StatefulWidget {
  final int userId;

  const _UserPublicAdsSection({required this.userId});

  @override
  State<_UserPublicAdsSection> createState() => _UserPublicAdsSectionState();
}

class _UserPublicAdsSectionState extends State<_UserPublicAdsSection> {
  late final Future<List<AdModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdsRepository().getAdsByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الإعلانات', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        FutureBuilder<List<AdModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: LoadingIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.inputBorderColor),
                ),
                child: Text(
                  'تعذّر تحميل الإعلانات.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final ads = snapshot.data ?? [];
            if (ads.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.inputBorderColor),
                ),
                child: Text(
                  'لا توجد إعلانات لعرضها.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: ads
                  .map(
                    (ad) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserPublicAdTile(ad: ad),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UserPublicAdTile extends StatelessWidget {
  final AdModel ad;

  const _UserPublicAdTile({required this.ad});

  String? _imageUrl() {
    final path = ad.firstImageUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = AppConstants.storageBaseUrl.endsWith('/')
        ? AppConstants.storageBaseUrl.substring(
            0,
            AppConstants.storageBaseUrl.length - 1,
          )
        : AppConstants.storageBaseUrl;
    final sanitized = path.startsWith('/') ? path.substring(1) : path;
    return '$base/$sanitized';
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl();
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.adDetails,
          arguments: {'adId': ad.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.inputBorderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: url != null
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ColoredBox(
                            color: context.surfaceBg,
                            child: Icon(
                              Icons.directions_car_outlined,
                              color: context.textHint,
                            ),
                          ),
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: context.surfaceBg,
                            child: Icon(
                              Icons.directions_car_outlined,
                              color: context.textHint,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: context.surfaceBg,
                          child: Icon(
                            Icons.directions_car_outlined,
                            color: context.textHint,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ad.priceFormatted,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (ad.locationLabel != null &&
                        ad.locationLabel!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ad.locationLabel!.trim(),
                        style: AppTextStyles.caption.copyWith(
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: context.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailItem {
  final String label;
  final String value;
  final bool isLtrValue;

  const _ProfileDetailItem({
    required this.label,
    required this.value,
    this.isLtrValue = false,
  });
}
