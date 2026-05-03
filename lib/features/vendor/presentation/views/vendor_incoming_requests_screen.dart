import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/vendor_requests_cubit.dart';
import '../../../home/data/repositories/search_requests_repository.dart';

/// Vendor Incoming Requests Screen
/// Shows pending search requests that match vendor's profile
class VendorIncomingRequestsScreen extends StatefulWidget {
  const VendorIncomingRequestsScreen({
    super.key,
    this.initialHighlightSearchRequestId,
  });

  /// When opened from a notification / realtime tap, emphasize this request card.
  final int? initialHighlightSearchRequestId;

  @override
  State<VendorIncomingRequestsScreen> createState() =>
      _VendorIncomingRequestsScreenState();
}

class _VendorIncomingRequestsScreenState
    extends State<VendorIncomingRequestsScreen> {
  final SearchRequestsRepository _searchRequestsRepo =
      SearchRequestsRepository();

  @override
  void initState() {
    super.initState();
    // Load incoming requests when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<VendorRequestsCubit>();
      RealtimeService.instance.onVendorFeedCard = (m) => cubit.applyFeedCard(m);
      RealtimeService.instance.onVendorFeedExpired = (m) {
        final id = _parseSearchRequestId(m);
        if (id != null) cubit.removeBySearchRequestId(id);
      };
      RealtimeService.instance.onVendorSearchRequestCreated = (_) =>
          cubit.getIncomingRequests();
      RealtimeService.instance.onVendorSearchRejected = (m) {
        final id = _parseSearchRequestId(m);
        if (id != null) cubit.removeBySearchRequestId(id);
      };
      cubit.getIncomingRequests();
    });
  }

  int? _parseSearchRequestId(Map<String, dynamic> m) {
    final v = m['search_request_id'] ?? m['id'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  void dispose() {
    RealtimeService.instance.onVendorFeedCard = null;
    RealtimeService.instance.onVendorFeedExpired = null;
    RealtimeService.instance.onVendorSearchRequestCreated = null;
    RealtimeService.instance.onVendorSearchRejected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('طلبات جديدة', style: AppTextStyles.headingMedium),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.notificationDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // TODO: Open menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: context.surfaceBg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'مباشر',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'طلبات بحث نشطة في منطقتك',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Requests List
          Expanded(
            child: BlocConsumer<VendorRequestsCubit, VendorRequestsState>(
              listener: (context, state) {
                if (state is VendorRequestsError) {
                  CustomToast.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is VendorRequestsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VendorRequestsLoaded) {
                  if (state.requests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: context.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات جديدة',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<VendorRequestsCubit>().getIncomingRequests();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: state.requests.asMap().entries.map((entry) {
                        final request = entry.value;
                        final index = entry.key;
                        return Column(
                          children: [
                            if (index > 0) const SizedBox(height: 16),
                            _buildRequestCardFromData(request),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }

                if (state is VendorRequestsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'إعادة المحاولة',
                          onPressed: () {
                            context
                                .read<VendorRequestsCubit>()
                                .getIncomingRequests();
                          },
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRequestCard({
    required String requestId,
    required String customerName,
    required bool isOnline,
    required String timeAgo,
    required String status,
    required String partName,
    required String carDetails,
    required String remainingTime,
    required bool isUrgent,
    required IconData icon,
    bool isCertified = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer
              Row(
                children: [
                  Icon(
                    isUrgent ? Icons.timer : Icons.timer_outlined,
                    color: isUrgent ? AppColors.error : AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'متبقي: $remainingTime د',
                    style: AppTextStyles.caption.copyWith(
                      color: isUrgent ? AppColors.error : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer Info Row
          Row(
            children: [
              // Profile Picture
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.surfaceBg,
                    ),
                    child: Center(
                      child: Text(
                        customerName[0],
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: OnlineIndicator(isOnline: true, size: 12),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isOnline)
                          Row(
                            children: [
                              OnlineIndicator(isOnline: true, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                'متصل',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.online,
                                ),
                              ),
                            ],
                          )
                        else if (isCertified)
                          Text(
                            'تاجر معتمد',
                            style: AppTextStyles.caption.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.primaryColor.withOpacity(0.2)
                                : context.surfaceBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: AppTextStyles.caption.copyWith(
                              color: isOnline
                                  ? AppColors.primaryColor
                                  : context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Part Info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القطعة المطلوبة',
                      style: AppTextStyles.caption.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: context.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          carDetails,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleReject(requestId),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.surfaceBg,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'تجاهل',
                    style: AppTextStyles.button.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'قبول',
                  icon: Icons.check,
                  onPressed: () => _handleAccept(requestId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return 'منذ قليل';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'منذ قليل';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  Widget _buildRequestCardFromData(Map<String, dynamic> request) {
    final requestId = request['id']?.toString() ?? '';
    final rid = int.tryParse(requestId);
    final highlight =
        widget.initialHighlightSearchRequestId != null &&
        rid == widget.initialHighlightSearchRequestId;
    final customer = request['customer'] as Map<String, dynamic>? ?? {};
    final customerName = customer['name']?.toString() ?? 'عميل';
    final isOnline = customer['is_online'] == true;
    final partText = request['part_text']?.toString() ?? '';
    final brand = request['brand'] as Map<String, dynamic>?;
    final model = request['model'] as Map<String, dynamic>?;
    final carDetails = [
      brand?['name'],
      model?['name'],
    ].where((s) => s != null && s.toString().isNotEmpty).join(' ');

    // Parse created_at for countdown and timeAgo
    final createdAt = _parseCreatedAt(request['created_at']);
    final timeAgo = _formatTimeAgo(createdAt);

    return _RequestCard(
      requestId: requestId,
      customerName: customerName,
      isOnline: isOnline,
      timeAgo: timeAgo,
      partName: partText,
      carDetails: carDetails,
      createdAt: createdAt,
      icon: Icons.build,
      highlight: highlight,
      onAccept: () => _handleAccept(requestId),
      onReject: () => _handleReject(requestId),
    );
  }

  DateTime? _parseCreatedAt(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) return raw;

    if (raw is int) {
      // Supports both unix seconds and milliseconds.
      final ms = raw > 1000000000000 ? raw : raw * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    if (raw is num) {
      final n = raw.toInt();
      final ms = n > 1000000000000 ? n : n * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final asInt = int.tryParse(text);
    if (asInt != null) {
      final ms = asInt > 1000000000000 ? asInt : asInt * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    return DateTime.tryParse(text);
  }

  void _handleAccept(String requestId) {
    final rootNav = Navigator.of(this.context, rootNavigator: true);
    final cubit = this.context.read<VendorRequestsCubit>();
    final scaffoldCtx = this.context;

    showModalBottomSheet(
      context: this.context,
      backgroundColor: this.context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AcceptRequestModal(
        requestId: requestId,
        onAccept: (message) async {
          Navigator.pop(sheetContext);
          try {
            final response = await _searchRequestsRepo.acceptSearchRequest(
              requestId: int.parse(requestId),
              note: message,
            );

            if (mounted) {
              CustomToast.showSuccess(scaffoldCtx, 'تم قبول الطلب بنجاح');
              cubit.getIncomingRequests();
            }

            final chatId =
                response['chat']?['id'] ?? response['data']?['chat']?['id'];
            if (chatId != null) {
              rootNav.pushNamed(
                AppRoutes.chatRoom,
                arguments: {'chatId': chatId.toString(), 'chatName': ''},
              );
            }
          } catch (e) {
            if (mounted) {
              CustomToast.showError(
                scaffoldCtx,
                e.toString().replaceAll('Exception: ', ''),
              );
            }
          }
        },
      ),
    );
  }

  void _handleReject(String requestId) {
    final scaffoldCtx = this.context;
    final cubit = this.context.read<VendorRequestsCubit>();

    showDialog(
      context: this.context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.cardBg,
        title: Text('تجاهل الطلب', style: AppTextStyles.headingSmall),
        content: Text(
          'هل أنت متأكد من تجاهل هذا الطلب؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: AppTextStyles.link),
          ),
          PrimaryButton(
            text: 'تجاهل',
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _searchRequestsRepo.rejectSearchRequest(
                  int.parse(requestId),
                );
                if (mounted) {
                  CustomToast.showSuccess(scaffoldCtx, 'تم تجاهل الطلب');
                  cubit.getIncomingRequests();
                }
              } catch (e) {
                if (mounted) {
                  CustomToast.showError(
                    scaffoldCtx,
                    e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Request card with live 48-hour countdown ────────────────────────────────

class _RequestCard extends StatefulWidget {
  final String requestId;
  final String customerName;
  final bool isOnline;
  final String timeAgo;
  final String partName;
  final String carDetails;
  final DateTime? createdAt;
  final IconData icon;
  final bool highlight;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.requestId,
    required this.customerName,
    required this.isOnline,
    required this.timeAgo,
    required this.partName,
    required this.carDetails,
    this.createdAt,
    required this.icon,
    required this.highlight,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  Timer? _timer;
  Duration _remaining = const Duration(hours: 48);
  static const _deadline = Duration(hours: 48);
  late final DateTime _startAt;

  @override
  void initState() {
    super.initState();
    _startAt = widget.createdAt ?? DateTime.now();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final elapsed = DateTime.now().difference(_startAt);
    final rem = _deadline - elapsed;
    setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero;
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final isUrgent = !expired && _remaining.inHours < 6;
    final timerColor = expired
        ? AppColors.error
        : isUrgent
        ? AppColors.warning
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: widget.highlight
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
        boxShadow: widget.highlight
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Countdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    expired
                        ? Icons.timer_off_outlined
                        : isUrgent
                        ? Icons.timer
                        : Icons.timer_outlined,
                    color: timerColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  expired
                      ? Text(
                          'انتهت مهلة القبول',
                          style: AppTextStyles.caption.copyWith(
                            color: timerColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Row(
                          children: [
                            Text(
                              'متبقي: ',
                              style: AppTextStyles.caption.copyWith(
                                color: timerColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$hours:$minutes:$seconds',
                              style: AppTextStyles.caption.copyWith(
                                color: timerColor,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
              Text(
                widget.timeAgo,
                style: AppTextStyles.caption.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer info row
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.surfaceBg,
                    ),
                    child: Center(
                      child: Text(
                        widget.customerName.isNotEmpty
                            ? widget.customerName[0].toUpperCase()
                            : '؟',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: OnlineIndicator(isOnline: true, size: 12),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (widget.isOnline)
                      Row(
                        children: [
                          OnlineIndicator(isOnline: true, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            'متصل',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.online,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Part info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القطعة المطلوبة',
                      style: AppTextStyles.caption.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.partName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.carDetails.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: context.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.carDetails,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReject,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.surfaceBg,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'تجاهل',
                    style: AppTextStyles.button.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'قبول',
                  icon: Icons.check,
                  onPressed: expired ? null : widget.onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptRequestModal extends StatefulWidget {
  final String requestId;
  final Function(String) onAccept;

  const _AcceptRequestModal({required this.requestId, required this.onAccept});

  @override
  State<_AcceptRequestModal> createState() => _AcceptRequestModalState();
}

class _AcceptRequestModalState extends State<_AcceptRequestModal> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('قبول الطلب', style: AppTextStyles.headingSmall),
              IconButton(
                icon: Icon(Icons.close, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Message Input
          Text('اكتب رسالتك الأولى للعميل', style: AppTextStyles.inputLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              hintText: 'اكتب رسالتك هنا...',
              hintStyle: AppTextStyles.inputHint,
              filled: true,
              fillColor: context.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.inputBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.inputBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.inputBorderFocused,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Accept Button
          PrimaryButton(
            text: 'قبول وإرسال',
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                widget.onAccept(_messageController.text.trim());
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
