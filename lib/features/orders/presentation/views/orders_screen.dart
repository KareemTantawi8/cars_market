import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/orders_cubit.dart';

/// Orders screen - Vendor can accept pending orders. Optional [orderId] to show Accept for one order (e.g. from notification).
class OrdersScreen extends StatefulWidget {
  final int? orderId;
  final String? orderTitle;

  const OrdersScreen({
    super.key,
    this.orderId,
    this.orderTitle,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit(),
      child: BlocConsumer<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state is OrderAccepted) {
            CustomToast.showSuccess(context, state.message);
            if (state.chatId != null) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.chatRoom,
                arguments: {
                  'chatId': state.chatId.toString(),
                  'chatName': widget.orderTitle ?? 'محادثة الطلب',
                },
              );
            } else {
              Navigator.maybePop(context);
            }
          }
          if (state is OrdersError) {
            CustomToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_forward, color: context.textPrimary),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text(
                'طلباتي',
                style: AppTextStyles.headingMedium,
              ),
              centerTitle: true,
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrdersState state) {
    if (state is OrdersAccepting) {
      return const Center(child: CircularProgressIndicator());
    }

    final orderId = widget.orderId;

    if (orderId != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: AppColors.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'طلب #$orderId',
                          style: AppTextStyles.headingSmall,
                        ),
                      ),
                    ],
                  ),
                  if (widget.orderTitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.orderTitle!,
                      style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'قبول الطلب ينقله إلى حالة "قيد التنفيذ" ويُنشئ أو يربط محادثة للتواصل مع العميل.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'قبول الطلب',
                    icon: Icons.check_circle_outline,
                    onPressed: state is OrdersAccepting
                        ? null
                        : () => context.read<OrdersCubit>().acceptOrder(orderId),
                    isLoading: state is OrdersAccepting,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: context.textHint,
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد طلبات معلقة',
              style: AppTextStyles.headingSmall.copyWith(
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'ستظهر هنا الطلبات التي تحتاج موافقتك. يمكنك أيضاً الوصول من الإشعارات عند وصول طلب جديد.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
