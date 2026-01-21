import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/segment_control.dart';

/// Subscription Plans Screen
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String _selectedDuration = 'monthly'; // 'monthly' or 'annual'

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      name: 'الأساسية',
      nameEn: 'Basic',
      monthlyPrice: 299,
      annualPrice: 2392, // 299 * 12 * 0.8 (20% discount)
      features: [
        '١٠ قطع غيار معروضة',
        'دردشة محدودة مع العملاء',
        'دعم فني عبر البريد',
      ],
      isPopular: false,
    ),
    SubscriptionPlan(
      name: 'الذهبية',
      nameEn: 'Golden',
      monthlyPrice: 999,
      annualPrice: 7992, // 999 * 12 * 0.8
      features: [
        'قطع غيار غير محدودة',
        'ظهور في مقدمة نتائج البحث',
        'شارة "بائع معتمد" فضية',
        'تحليلات المبيعات الأسبوعية',
        'دعم فني VIP ٢٤/٧',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      name: 'الفضية',
      nameEn: 'Silver',
      monthlyPrice: 599,
      annualPrice: 4792, // 599 * 12 * 0.8
      features: [
        '٥٠ قطعة غيار معروضة',
        'دردشة غير محدودة',
        'دعم فني سريع',
      ],
      isPopular: false,
    ),
  ];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            const SizedBox(height: 32),
            // Duration Toggle
            _buildDurationToggle(),
            const SizedBox(height: 32),
            // Subscription Plans
            ..._plans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPlanCard(plan),
                )),
            const SizedBox(height: 32),
            // Why Choose Our Platform Section
            _buildBenefitsSection(),
            const SizedBox(height: 32),
            // Footer
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خطط الاشتراك للموردين',
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'اختر خطتك المناسبة',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'قم بزيادة مبيعات قطع الغيار والوصول لآلاف العملاء في مصر',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            'شهري',
            _selectedDuration == 'monthly',
            () => setState(() => _selectedDuration = 'monthly'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              _buildToggleButton(
                'سنوي',
                _selectedDuration == 'annual',
                () => setState(() => _selectedDuration = 'annual'),
              ),
              Positioned(
                top: -4,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'وفر 20%',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.inputBorder,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final price = _selectedDuration == 'monthly'
        ? plan.monthlyPrice
        : plan.annualPrice;
    final priceText = _selectedDuration == 'monthly' ? 'شهر' : 'سنة';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: plan.isPopular
                ? Border.all(color: AppColors.ratingStar, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.ratingStar.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.ratingStar,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الأكثر طلباً',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ratingStar,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (plan.isPopular) const SizedBox(height: 12),
              Text(
                plan.name,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$price ج.م',
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/ $priceText',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'اشترك الآن',
                onPressed: () {
                  // TODO: Handle subscription
                  _handleSubscribe(plan);
                },
                backgroundColor: plan.isPopular
                    ? AppColors.primaryColor
                    : AppColors.buttonPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لماذا تختار منصتنا؟',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          icon: Icons.trending_up,
          title: 'زيادة في المبيعات',
          description:
              'تجارنا حققوا زيادة %۲۰۰ في الطلبات خلال أول شهر',
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          icon: Icons.people,
          title: 'قاعدة عملاء ضخمة',
          description:
              'وصول مباشر لأصحاب السيارات والورش في كافة المحافظات',
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          icon: Icons.verified_user,
          title: 'ثقة ومصداقية',
          description:
              'احصل على شارة توثيق تجعل العميل يختارك أنت دون غيرك',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'تحتاج لخطة مخصصة لشركتك؟',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // TODO: Navigate to contact sales team
            },
            child: Text(
              'تواصل مع فريق المبيعات',
              style: AppTextStyles.link.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(SubscriptionPlan plan) {
    // TODO: Implement subscription logic
    print('Subscribing to ${plan.name} - ${_selectedDuration}');
  }
}

/// Subscription Plan Model
class SubscriptionPlan {
  final String name;
  final String nameEn;
  final int monthlyPrice;
  final int annualPrice;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.name,
    required this.nameEn,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    this.isPopular = false,
  });
}

