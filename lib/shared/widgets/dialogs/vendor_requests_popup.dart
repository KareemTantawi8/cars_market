import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../common/custom_toast.dart';
import '../common/online_indicator.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Shows the vendor pending-requests popup dialog.
/// Call from [VendorDashboardScreen] after loading or on Reverb event.
Future<void> showVendorRequestsPopup(BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => const _VendorRequestsPopup(),
    transitionBuilder: (ctx, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Internal popup widget
// ---------------------------------------------------------------------------

class _VendorRequestsPopup extends StatefulWidget {
  const _VendorRequestsPopup();

  @override
  State<_VendorRequestsPopup> createState() => _VendorRequestsPopupState();
}

class _VendorRequestsPopupState extends State<_VendorRequestsPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bellController;
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    HapticFeedback.mediumImpact();
    _fetchRequests();
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await ApiClient().get(
        ApiEndpoints.vendorPendingRequestsSummary,
      );
      final data = response.data;
      final List<dynamic> raw =
          data['data'] ?? data['requests'] ?? [];
      if (mounted) {
        setState(() {
          _requests = raw.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحميل الطلبات';
          _loading = false;
        });
      }
    }
  }

  void _dismiss() => Navigator.of(context, rootNavigator: true).pop();

  void _viewAll() {
    _dismiss();
    Navigator.of(context, rootNavigator: true)
        .pushNamed(AppRoutes.vendorIncomingRequests);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A2340).withOpacity(0.97),
                        const Color(0xFF0D1A30).withOpacity(0.97),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.55),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Flexible(child: _buildBody()),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final count = _requests.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Animated bell
          AnimatedBuilder(
            animation: _bellController,
            builder: (_, __) => Transform.rotate(
              angle: (_bellController.value - 0.5) * 0.5,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.warning.withOpacity(0.35),
                      AppColors.warning.withOpacity(0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلبات عملاء جديدة',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                if (!_loading && _error == null)
                  Text(
                    count == 0
                        ? 'لا توجد طلبات معلقة'
                        : '$count ${count == 1 ? "طلب ينتظر ردك" : "طلبات تنتظر ردك"}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryLight.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.error.withOpacity(0.7), size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white.withOpacity(0.6))),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                color: AppColors.primaryLight.withOpacity(0.4), size: 52),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات جديدة في الوقت الحالي',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        request: _requests[i],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _viewAll,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.list_alt_rounded, size: 20),
          label: const Text('عرض كل الطلبات'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request card with live countdown
// ---------------------------------------------------------------------------

class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request;

  const _RequestCard({
    required this.request,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  Timer? _timer;
  Duration _remaining = const Duration(hours: 48);

  @override
  void initState() {
    super.initState();
    _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _computeRemaining();
    });
  }

  void _computeRemaining() {
    final raw = widget.request['created_at'] ??
        widget.request['updated_at'];
    DateTime? start;
    if (raw is String && raw.isNotEmpty) start = DateTime.tryParse(raw);
    start ??= DateTime.now();
    final elapsed = DateTime.now().difference(start);
    final rem = const Duration(hours: 48) - elapsed;
    setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _requestId =>
      (widget.request['id'] ?? '').toString();

  String get _partName =>
      widget.request['part_text']?.toString() ?? '—';

  String get _vehicleLabel {
    final v = widget.request['vehicle'];
    if (v is Map) {
      return v['vehicle_label']?.toString() ??
          [v['brand'], v['model']]
              .where((s) => s != null && s.toString().isNotEmpty)
              .join(' ');
    }
    return '';
  }

  Map<String, dynamic> get _customer {
    final c = widget.request['customer'];
    if (c is Map<String, dynamic>) return c;
    if (c is Map) return Map<String, dynamic>.from(c);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero;
    final isUrgent = !expired && _remaining.inHours < 6;
    final timerColor = expired
        ? AppColors.error
        : isUrgent
            ? AppColors.warning
            : AppColors.success;

    final customerName =
        _customer['display_name']?.toString() ?? 'عميل';
    final isOnline = _customer['is_online'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: customer + timer
          Row(
            children: [
              // Avatar + online dot
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor.withOpacity(0.25),
                    ),
                    child: Center(
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : '؟',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: OnlineIndicator(isOnline: true, size: 10),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (isOnline)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.online,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'متصل الآن',
                            style: TextStyle(
                              color: AppColors.online.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Countdown chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: timerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: timerColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      expired
                          ? Icons.timer_off_outlined
                          : Icons.timer_outlined,
                      color: timerColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expired
                          ? 'انتهت'
                          : '${_remaining.inHours.toString().padLeft(2, '0')}:'
                              '${(_remaining.inMinutes % 60).toString().padLeft(2, '0')}:'
                              '${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: timerColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: part + vehicle
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.build_rounded,
                    color: AppColors.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _partName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_vehicleLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.directions_car_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.45)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _vehicleLabel,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 12),

          // Row 3: action button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: expired ? null : () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(AppRoutes.vendorIncomingRequests);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('عرض التفاصيل والرد',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
