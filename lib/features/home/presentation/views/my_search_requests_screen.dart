import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/search_requests_cubit.dart';

/// Customer's My Search Requests Screen — lists requests and allows rating
class MySearchRequestsScreen extends StatelessWidget {
  const MySearchRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchRequestsCubit()..getMySearchRequests(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: context.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text('طلبات البحث', style: AppTextStyles.headingMedium),
          centerTitle: true,
        ),
        body: BlocBuilder<SearchRequestsCubit, SearchRequestsState>(
          builder: (context, state) {
            if (state is SearchRequestsLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is SearchRequestsError) {
              return Center(
                child: ErrorState(
                  message: state.message,
                  onRetry: () =>
                      context.read<SearchRequestsCubit>().getMySearchRequests(),
                ),
              );
            }
            if (state is MySearchRequestsLoaded) {
              if (state.requests.isEmpty) {
                return _buildEmpty(context);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<SearchRequestsCubit>().getMySearchRequests(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = state.requests[index];
                    return _RequestCard(request: req);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: context.textHint),
            const SizedBox(height: 20),
            Text(
              'لا توجد طلبات',
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'لم تقم بإرسال أي طلبات بحث بعد.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single request card
// ─────────────────────────────────────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  late Map<String, dynamic> _req;
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    _req = widget.request;
    _rated = _req['rating'] != null;
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      default:
        return status ?? '—';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.primaryColor;
      default:
        return AppColors.info;
    }
  }

  bool _canRate(String? status) =>
      (status == 'accepted' || status == 'completed') && !_rated;

  static bool _mapIsVerified(Map<String, dynamic> m) {
    return m['is_verified'] == true ||
        m['verified'] == true ||
        m['is_certified'] == true;
  }

  /// True if API marks the accepting vendor as verified (root or nested `vendor`).
  bool _vendorIsVerified() {
    for (final key in ['vendor', 'accepted_by']) {
      final raw = _req[key];
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      if (_mapIsVerified(m)) return true;
      final nested = m['vendor'];
      if (nested is Map && _mapIsVerified(Map<String, dynamic>.from(nested))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final status = _req['status'] as String?;
    final partText = _req['part_text'] as String? ??
        _req['part_name'] as String? ??
        'طلب قطعة';
    final id = _req['id'];
    final vendorName = (_req['vendor'] as Map?)?['name'] as String? ??
        (_req['accepted_by'] as Map?)?['name'] as String?;
    final vendorVerified = _vendorIsVerified();
    final ratingData = _req['rating'];
    final existingRating = ratingData is Map ? ratingData['rating'] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  partText,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: AppTextStyles.caption.copyWith(
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (id != null) ...[
            const SizedBox(height: 4),
            Text(
              'طلب #$id',
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary),
            ),
          ],
          if (vendorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.store_outlined,
                    size: 14, color: context.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendorName,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vendorVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          // Existing rating display
          if (_rated && existingRating != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ...List.generate(5, (i) {
                  final filled = i < (existingRating as num).toInt();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: AppColors.ratingStar,
                    size: 18,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  'تم التقييم',
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ],
          // Rate button
          if (_canRate(status)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(context, id as int),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('تقييم التاجر'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ratingStar,
                  side: BorderSide(color: AppColors.ratingStar),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(BuildContext context, int requestId) async {
    final cubit = context.read<SearchRequestsCubit>();
    int selectedRating = 0;
    final reviewController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('تقييم التاجر'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'كيف كانت تجربتك مع التاجر؟',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedRating = i + 1),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < selectedRating
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
                      hintText: 'اكتب تعليقك (اختياري)',
                      hintStyle: AppTextStyles.inputHint,
                      filled: true,
                      fillColor: context.inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: context.inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: context.inputBorderColor),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('إرسال التقييم'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) return;

    final review = reviewController.text.trim();
    final result = await cubit.rateSearchRequest(
      requestId: requestId,
      rating: selectedRating,
      review: review.isEmpty ? null : review,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _rated = true;
        _req = {
          ..._req,
          'rating': {'rating': selectedRating, 'review': review},
        };
      });
      CustomToast.showSuccess(context, 'تم إرسال التقييم بنجاح');
    } else {
      CustomToast.showError(context, 'فشل إرسال التقييم، حاول مجدداً');
    }
  }
}
