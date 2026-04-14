import 'dart:async';
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
  /// وقت إنشاء الطلب — يُستخدم لحساب العداد التنازلي لـ 48 ساعة.
  final DateTime? createdAt;

  const OrdersScreen({
    super.key,
    this.orderId,
    this.orderTitle,
    this.createdAt,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Timer? _countdownTimer;
  Duration _remaining = const Duration(hours: 48);

  static const _deadline = Duration(hours: 48);

  /// Reference point for the 48-hour window: the order creation time if known,
  /// otherwise the moment the screen was opened (gives vendor the full window).
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.createdAt ?? DateTime.now();
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final elapsed = DateTime.now().difference(_startedAt);
    final rem = _deadline - elapsed;
    setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

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
                border: Border.all(color: context.inputBorderColor),
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
                  const SizedBox(height: 20),
                  _buildCountdown(),
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

  Widget _buildCountdown() {
    final expired = _remaining == Duration.zero;
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    final isUrgent = !expired && _remaining.inHours < 6;
    final color = expired
        ? AppColors.error
        : isUrgent
            ? AppColors.warning
            : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                expired ? 'انتهت مهلة القبول' : 'الوقت المتبقي للرد',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!expired) ...[
            const SizedBox(height: 8),
            Text(
              '$hours:$minutes:$seconds',
              style: AppTextStyles.headingMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'من أصل 48 ساعة',
              style: AppTextStyles.caption.copyWith(color: color.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
