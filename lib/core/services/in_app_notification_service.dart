import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigation/root_navigator.dart';
import '../theme/app_colors.dart';
import 'notification_navigation.dart';

/// In-app overlay banner for realtime / foreground alerts.
/// Slides down from the top, auto-dismisses, and navigates on tap.
class InAppNotificationService {
  InAppNotificationService._();

  static OverlayEntry? _currentEntry;

  static void dismiss() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }

  static void show({
    required String title,
    String? body,
    IconData icon = Icons.notifications_outlined,
    Color iconColor = AppColors.primaryColor,
    required Map<String, dynamic> notificationMapForNavigation,
  }) {
    if (kDebugMode) debugPrint('[InAppNotif] show: "$title"');
    dismiss();

    final navState = rootNavigatorKey.currentState;
    if (navState == null) {
      if (kDebugMode) debugPrint('[InAppNotif] ⚠ rootNavigatorKey.currentState is null');
      return;
    }
    final overlay = navState.overlay;
    if (overlay == null) {
      if (kDebugMode) debugPrint('[InAppNotif] ⚠ overlay is null');
      return;
    }

    late final OverlayEntry entry;

    void removeEntry() {
      if (_currentEntry == entry) {
        try {
          entry.remove();
        } catch (_) {}
        _currentEntry = null;
      }
    }

    entry = OverlayEntry(
      builder: (_) => _InAppBanner(
        title: title,
        body: body,
        icon: icon,
        iconColor: iconColor,
        onTap: () {
          removeEntry();
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) {
            navigateFromNotificationMap(ctx, notificationMapForNavigation);
          }
        },
        onDismissed: removeEntry,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  // ─── Convenience constructors for known event types ───────────────────────

  /// Customer: `new-message.sent` Reverb payload.
  static void showNewMessageReverb(Map<String, dynamic> data) {
    if (kDebugMode) debugPrint('[InAppNotif] showNewMessageReverb called');
    final n = data['notification'];
    String title = 'رسالة جديدة';
    String body = '';
    if (n is Map<String, dynamic>) {
      title = n['title']?.toString() ?? title;
      body = n['body']?.toString() ?? '';
    }
    if (body.isEmpty && data['message'] is Map) {
      body = (data['message'] as Map)['body']?.toString() ?? '';
    }

    final map = <String, dynamic>{
      'type': 'new_message',
      ...data,
      'title': title,
      'body': body,
    };

    show(
      title: title,
      body: body.isEmpty ? null : body,
      icon: Icons.chat_bubble_rounded,
      iconColor: AppColors.primaryLight,
      notificationMapForNavigation: map,
    );
  }

  /// Customer: `search-request.accepted` Reverb payload.
  static void showSearchAcceptedReverb(Map<String, dynamic> data) {
    if (kDebugMode) debugPrint('[InAppNotif] showSearchAcceptedReverb called');
    final vendor = data['vendor'];
    final vendorName =
        vendor is Map ? vendor['company_name']?.toString() : null;
    const title = 'تم قبول طلب البحث';
    final body = vendorName != null && vendorName.isNotEmpty
        ? 'قام $vendorName بقبول طلبك'
        : 'يمكنك بدء المحادثة الآن';

    final map = <String, dynamic>{
      'type': 'search_approved',
      'title': title,
      'body': body,
      ...data,
    };

    show(
      title: title,
      body: body,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      notificationMapForNavigation: map,
    );
  }

  /// Vendor: `search-request.created` Reverb payload.
  static void showVendorNewSearchRequest(Map<String, dynamic> data) {
    if (kDebugMode) debugPrint('[InAppNotif] showVendorNewSearchRequest called');
    final sr = data['search_request'];
    Map<String, dynamic>? srMap;
    if (sr is Map<String, dynamic>) {
      srMap = sr;
    } else if (sr is Map) {
      srMap = Map<String, dynamic>.from(sr);
    }

    final id = srMap?['id'];
    final searchRequestId =
        id is int ? id : int.tryParse(id?.toString() ?? '');

    final customer = srMap?['customer'];
    final customerName =
        customer is Map ? customer['name']?.toString() : null;
    final partText = srMap?['part_text']?.toString() ?? '';

    const title = 'طلب بحث جديد';
    final body = [
      if (customerName != null && customerName.isNotEmpty) customerName,
      if (partText.isNotEmpty) partText,
    ].join(' — ');

    final map = <String, dynamic>{
      'type': 'search_request',
      'title': title,
      'body': body.isEmpty ? partText : body,
      if (searchRequestId != null)
        'meta': {'search_request_id': searchRequestId},
      if (searchRequestId != null) 'search_request_id': searchRequestId,
      'search_request': srMap,
      ...data,
    };

    show(
      title: title,
      body: body.isEmpty ? (partText.isEmpty ? null : partText) : body,
      icon: Icons.search_rounded,
      iconColor: AppColors.warning,
      notificationMapForNavigation: map,
    );
  }
}

// ─── Animated overlay banner ────────────────────────────────────────────────

class _InAppBanner extends StatefulWidget {
  final String title;
  final String? body;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _InAppBanner({
    required this.title,
    this.body,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoHide;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _autoHide = Timer(const Duration(seconds: 6), _animateOut);
  }

  Future<void> _animateOut() async {
    if (_gone || !mounted) return;
    _gone = true;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _autoHide?.cancel();
                if (!_gone) {
                  _gone = true;
                  widget.onTap();
                }
              },
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -100) {
                  _autoHide?.cancel();
                  _animateOut();
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.fromLTRB(12, topPad + 8, 12, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, Color(0xFF1565C0)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.iconColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(widget.icon,
                            color: widget.iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Title + body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.body != null &&
                                widget.body!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.body!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Arrow badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 13,
                        ),
                      ),
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
}
