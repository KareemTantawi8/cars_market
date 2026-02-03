import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/subscription_cubit.dart';
import '../../data/models/plan_model.dart';

/// Plan Details Screen - Shows full details of a subscription plan
class PlanDetailsScreen extends StatelessWidget {
  final int planId;

  const PlanDetailsScreen({
    super.key,
    required this.planId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionCubit()..fetchPlanDetails(planId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'تفاصيل الخطة',
            style: AppTextStyles.headingMedium,
          ),
        ),
        body: BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, state) {
            if (state is SubscriptionLoading) {
              return const Center(child: LoadingIndicator());
            }

            if (state is SubscriptionError) {
              return Center(
                child: ErrorState(
                  message: state.message,
                  onRetry: () {
                    context.read<SubscriptionCubit>().fetchPlanDetails(planId);
                  },
                ),
              );
            }

            if (state is PlanDetailsLoaded) {
              return _buildPlanDetails(context, state.plan);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPlanDetails(BuildContext context, PlanModel plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Header
          _buildPlanHeader(plan),
          const SizedBox(height: 24),
          
          // Plan Description
          if (plan.description != null) ...[
            Text(
              plan.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Price Section
          _buildPriceSection(plan),
          const SizedBox(height: 24),

          // Features Section
          _buildFeaturesSection(plan),
          const SizedBox(height: 24),

          // Additional Details
          _buildAdditionalDetails(plan),
          const SizedBox(height: 32),

          // Subscribe Button
          PrimaryButton(
            text: 'اشترك الآن',
            onPressed: () {
              _handleSubscribe(context, plan);
            },
            backgroundColor: plan.isPopular
                ? AppColors.primaryColor
                : AppColors.buttonPrimary,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlanHeader(PlanModel plan) {
    return Container(
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
            style: AppTextStyles.headingLarge,
          ),
          if (plan.badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                plan.badge!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection(PlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${plan.monthlyPrice.toInt()} ج.م',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ شهر',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(PlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المميزات',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails(PlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل إضافية',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          if (plan.unlimitedParts)
            _buildDetailItem(
              icon: Icons.all_inclusive,
              label: 'قطع الغيار',
              value: 'غير محدود',
            )
          else if (plan.maxParts != null)
            _buildDetailItem(
              icon: Icons.inventory_2,
              label: 'قطع الغيار',
              value: '${plan.maxParts} قطعة',
            ),
          if (plan.priorityInSearch) ...[
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.trending_up,
              label: 'الظهور في البحث',
              value: 'في المقدمة',
            ),
          ],
          if (plan.supportType != null) ...[
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.support_agent,
              label: 'الدعم الفني',
              value: plan.supportType!,
            ),
          ],
          if (plan.hasAnalytics) ...[
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.analytics,
              label: 'التحليلات',
              value: 'متاحة',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleSubscribe(BuildContext context, PlanModel plan) {
    // TODO: Implement subscription logic with payment
    // After successful subscription:
    // 1. Save subscription data
    // 2. Navigate to vendor dashboard
    print('Subscribing to ${plan.name} (ID: ${plan.id})');
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text(
          'تأكيد الاشتراك',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'هل تريد الاشتراك في خطة ${plan.name} بسعر ${plan.monthlyPrice.toInt()} ج.م شهرياً؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to payment/subscription confirmation
              // For now, just show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('سيتم تفعيل الاشتراك قريباً'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(
              'تأكيد',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

