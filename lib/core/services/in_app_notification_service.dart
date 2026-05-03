import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/root_navigator.dart';
import '../theme/app_colors.dart';
import 'notification_navigation.dart';
import 'notification_payload.dart';
import 'push_notification_service.dart';

/// In-app overlay banner for realtime / foreground alerts.
/// Slides down from the top, auto-dismisses after 6 s, and navigates on tap.
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
    _NotifType type = _NotifType.generic,
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

    HapticFeedback.mediumImpact();

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
        type: type,
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
      type: _NotifType.message,
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
      type: _NotifType.accepted,
      notificationMapForNavigation: map,
    );
  }

  /// Vendor: `search-request.created` Reverb payload.
  static Future<void> showVendorNewSearchRequest(Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('[InAppNotif] showVendorNewSearchRequest called');
    final map = vendorSearchRequestNavigationMap(data);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) {
      if (kDebugMode) {
        debugPrint('[InAppNotif] skip overlay (not resumed); tray already posted');
      }
      return;
    }
    await PushNotificationService.instance
        .cancelVendorSearchLocalNotification(vendorSearchLocalNotificationId(map));
    const title = 'طلب بحث جديد';
    final bodyLine = map['body']?.toString() ?? '';
    final partText = (map['search_request'] is Map
            ? (map['search_request'] as Map)['part_text']
            : null)
        ?.toString() ??
        '';

    show(
      title: title,
      body: bodyLine.isEmpty
          ? (partText.isEmpty ? null : partText)
          : bodyLine,
      icon: Icons.search_rounded,
      iconColor: AppColors.warning,
      type: _NotifType.searchRequest,
      notificationMapForNavigation: map,
    );
  }
}

// ─── Notification type enum ─────────────────────────────────────────────────

enum _NotifType { generic, message, accepted, searchRequest }

extension _NotifTypeExt on _NotifType {
  String get label {
    switch (this) {
      case _NotifType.message:
        return 'رسالة';
      case _NotifType.accepted:
        return 'قُبل طلبك';
      case _NotifType.searchRequest:
        return 'طلب جديد';
      case _NotifType.generic:
        return 'إشعار';
    }
  }

  Color get labelBg {
    switch (this) {
      case _NotifType.message:
        return AppColors.primaryColor;
      case _NotifType.accepted:
        return AppColors.success;
      case _NotifType.searchRequest:
        return AppColors.warning;
      case _NotifType.generic:
        return AppColors.info;
    }
  }
}

// ─── Animated overlay banner ────────────────────────────────────────────────

class _InAppBanner extends StatefulWidget {
  final String title;
  final String? body;
  final IconData icon;
  final Color iconColor;
  final _NotifType type;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _InAppBanner({
    required this.title,
    this.body,
    required this.icon,
    required this.iconColor,
    required this.type,
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
  // Progress for the auto-dismiss bar
  double _progress = 1.0;
  Timer? _progressTimer;

  static const _duration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _autoHide = Timer(_duration, _animateOut);

    // Tick progress bar every 60 ms
    const tickMs = 60;
    final totalTicks = _duration.inMilliseconds / tickMs;
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (t) {
        if (!mounted) return;
        setState(() => _progress = 1.0 - (t.tick / totalTicks).clamp(0.0, 1.0));
      },
    );
  }

  Future<void> _animateOut() async {
    if (_gone || !mounted) return;
    _gone = true;
    _progressTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _progressTimer?.cancel();
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
                _progressTimer?.cancel();
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
              onHorizontalDragEnd: (d) {
                _autoHide?.cancel();
                _animateOut();
              },
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, topPad + 8, 12, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryDark.withOpacity(0.95),
                              const Color(0xFF0D2A5C).withOpacity(0.95),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.iconColor.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.55),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                              child: Row(
                                children: [
                                  // Icon container
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: widget.iconColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: widget.iconColor.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(widget.icon,
                                        color: widget.iconColor, size: 23),
                                  ),
                                  const SizedBox(width: 12),

                                  // Text section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Type label chip + title
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: widget.type.labelBg
                                                    .withOpacity(0.25),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: widget.type.labelBg
                                                      .withOpacity(0.5),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                widget.type.label,
                                                style: TextStyle(
                                                  color: widget.type.labelBg,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                widget.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                  height: 1.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.body != null &&
                                            widget.body!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            widget.body!,
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.72),
                                              fontSize: 12.5,
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

                                  // Arrow
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white.withOpacity(0.55),
                                      size: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Auto-dismiss progress bar
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(20)),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 3,
                                backgroundColor: Colors.white.withOpacity(0.07),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.iconColor.withOpacity(0.7),
                                ),
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
          ),
        ),
      ),
    );
  }
}
