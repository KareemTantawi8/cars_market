import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/common/online_indicator.dart';

/// Vendor Profile Screen
class VendorProfileScreen extends StatelessWidget {
  final String vendorId;
  final String vendorName;

  const VendorProfileScreen({
    super.key,
    required this.vendorId,
    this.vendorName = 'المهندس لقطع الغيار',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Background Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: AppColors.textPrimary),
                onPressed: () {
                  // TODO: Add to favorites
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.textPrimary),
                onPressed: () {
                  // TODO: Share vendor
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.7),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Info Card
                  _buildVendorInfoCard(),
                  const SizedBox(height: 24),
                  // Supported Brands Section
                  _buildSupportedBrandsSection(),
                  const SizedBox(height: 24),
                  // Available Services Section
                  _buildAvailableServicesSection(),
                  const SizedBox(height: 24),
                  // Action Buttons
                  _buildActionButtons(context),
                  const SizedBox(height: 24),
                  // Location Section
                  _buildLocationSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Verification
          Row(
            children: [
              Expanded(
                child: Text(
                  vendorName,
                  style: AppTextStyles.headingMedium,
                ),
              ),
              const Icon(
                Icons.verified,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            'مركز معتمد . قطع غيار أصلية واستيراد',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.access_time,
                  value: 'مفتوح',
                  subtitle: 'حتى ١٠ م',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.speed,
                  value: '٥ دقائق',
                  subtitle: 'سرعة الرد',
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.star,
                  value: '٤.٩',
                  subtitle: '٢٠٠ تقييم',
                  color: AppColors.ratingStar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الماركات المدعومة',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildBrandCard('مرسيدس', Icons.star),
            const SizedBox(width: 12),
            _buildBrandCard('بي ام دبليو', Icons.star),
            const SizedBox(width: 12),
            _buildBrandCard('هيونداي', Icons.star),
            const SizedBox(width: 12),
            _buildBrandCard('تويوتا', Icons.star),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandCard(String brandName, IconData icon) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              brandName,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخدمات المتوفرة',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildServiceChip('تغيير زيت'),
            _buildServiceChip('تيل فرامل'),
            _buildServiceChip('صيانة موتور'),
            _buildServiceChip('عفشة'),
            _buildServiceChip('فحص كمبيوتر'),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceChip(String serviceName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        serviceName,
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Handle phone call
            },
            icon: const Icon(Icons.phone),
            label: const Text('اتصال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.chatRoom,
                arguments: {
                  'chatId': vendorId,
                  'vendorName': vendorName,
                },
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('بدء محادثة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الموقع',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        // Map Placeholder
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Center(
            child: Icon(
              Icons.map,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.primaryColor,
                ),
                onPressed: () {
                  // TODO: Open map/directions
                },
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدقي، الجيزة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '١٢ شارع التحرير، أمام بنك مصر',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

