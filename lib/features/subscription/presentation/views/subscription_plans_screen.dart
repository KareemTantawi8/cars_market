import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/subscription_cubit.dart';
import '../../data/models/plan_model.dart';

/// Subscription Plans Screen
class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionCubit()..fetchPlans(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: context.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
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
                    context.read<SubscriptionCubit>().fetchPlans();
                  },
                ),
              );
            }

            if (state is PlansLoaded) {
              return _buildPlansList(context, state.plans);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, List<PlanModel> plans) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(context),
          const SizedBox(height: 32),
          // Subscription Plans
          ...plans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(context, plan),
              )),
          const SizedBox(height: 32),
          // Why Choose Our Platform Section
          _buildBenefitsSection(context),
          const SizedBox(height: 32),
          // Footer
          _buildFooter(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, PlanModel plan) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
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
                    '${plan.monthlyPrice.toInt()} ج.م',
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/ شهر',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
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
                  _handleSubscribe(context, plan);
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

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لماذا تختار منصتنا؟',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(context,
          icon: Icons.trending_up,
          title: 'زيادة في المبيعات',
          description:
              'تجارنا حققوا زيادة %۲۰۰ في الطلبات خلال أول شهر',
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(context,
          icon: Icons.people,
          title: 'قاعدة عملاء ضخمة',
          description:
              'وصول مباشر لأصحاب السيارات والورش في كافة المحافظات',
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(context,
          icon: Icons.verified_user,
          title: 'ثقة ومصداقية',
          description:
              'احصل على شارة توثيق تجعل العميل يختارك أنت دون غيرك',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
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
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardBg,
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

  void _handleSubscribe(BuildContext context, PlanModel plan) {
    // Navigate to plan details screen
    Navigator.of(context).pushNamed(
      AppRoutes.planDetails,
      arguments: {'planId': plan.id},
    );
  }
}
