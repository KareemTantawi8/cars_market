import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _particleController;
  late final AnimationController _pulseController;

  // Logo animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotate;

  // Text animations
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Tagline
  late final Animation<double> _taglineOpacity;

  // Glow pulse
  late final Animation<double> _pulse;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // ── Logo ──────────────────────────────────────────────────────────────
    _logoScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.3, end: 1.12)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 65),
      TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.55),
    ));

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeIn),
    ));

    _logoRotate = Tween(begin: -0.15, end: 0.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ));

    // ── App name ──────────────────────────────────────────────────────────
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.38, 0.62, curve: Curves.easeOut),
    ));

    _titleSlide = Tween(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.38, 0.65, curve: Curves.easeOutCubic),
    ));

    // ── Subtitle (قطع غيار...) ────────────────────────────────────────────
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.52, 0.74, curve: Curves.easeOut),
    ));

    _subtitleSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.52, 0.76, curve: Curves.easeOutCubic),
    ));

    // ── Tagline dots ──────────────────────────────────────────────────────
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.68, 0.86, curve: Curves.easeOut),
    ));

    // ── Glow pulse ────────────────────────────────────────────────────────
    _pulse = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Start ─────────────────────────────────────────────────────────────
    _mainController.forward();
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), _navigate);
      }
    });
  }

  void _navigate() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    final token = StorageService.getAuthToken();
    final userType = StorageService.getUserType();
    if (token != null && token.isNotEmpty) {
      unawaited(RealtimeService.instance.start());
      unawaited(PushNotificationService.instance.registerToken());
      unawaited(
        PushNotificationService.instance.establishNotificationSyncBaseline(),
      );
      if (userType == AppConstants.userTypeVendor) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.vendorDashboard, (r) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
      }
      // Navigate to the screen indicated by the notification tap (if any).
      // Must run after the destination route is on the stack.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.instance.consumePendingInitialMessage();
      });
    } else {
      // Guests land on login first; they can browse via "تصفح بدون تسجيل" on LoginScreen.
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF060D1F),
                  Color(0xFF0A1833),
                  Color(0xFF0D2248),
                  AppColors.primaryDark,
                ],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),

          // ── Animated particle rings ────────────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _RingsPainter(_particleController.value),
              );
            },
          ),

          // ── Glow blob behind logo ──────────────────────────────────────
          Align(
            alignment: const Alignment(0, -0.18),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                return Container(
                  width: 220 * _pulse.value,
                  height: 220 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.22 * _pulse.value),
                        AppColors.primaryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (_, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotate.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _LogoWidget(),
                ),

                const SizedBox(height: 36),

                // App name
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (_, __) {
                    return FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'وش سلندر',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: AppColors.primaryColor,
                                blurRadius: 24,
                              ),
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Subtitle
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (_, __) {
                    return FadeTransition(
                      opacity: _subtitleOpacity,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: Text(
                          'قطع غيار وخدمات في مكان واحد',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.72),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Decorative dots
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (_, __) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final isCenter = i == 1;
                          return AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isCenter ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isCenter
                                      ? AppColors.primaryColor
                                          .withOpacity(0.7 + 0.3 * _pulse.value)
                                      : Colors.white.withOpacity(0.35),
                                  boxShadow: isCenter
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.6),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo widget ──────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/images/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.directions_car_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Rings painter ────────────────────────────────────────────────────────────

class _RingsPainter extends CustomPainter {
  final double progress;
  _RingsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    final rings = [
      (radius: 160.0, opacity: 0.06, speed: 1.0),
      (radius: 240.0, opacity: 0.04, speed: 0.7),
      (radius: 330.0, opacity: 0.025, speed: 0.5),
    ];

    for (final ring in rings) {
      final phase = (progress * ring.speed) % 1.0;
      final r = ring.radius + phase * 30;
      final paint = Paint()
        ..color = AppColors.primaryColor
            .withOpacity(ring.opacity * (1.0 - phase * 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Floating particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final angle = (rng.nextDouble() * math.pi * 2) +
          progress * math.pi * 2 * (rng.nextBool() ? 0.2 : -0.15);
      final dist = 120.0 + rng.nextDouble() * 220;
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist;
      final opacity = 0.06 + rng.nextDouble() * 0.14;
      particlePaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(px, py), 2.0 + rng.nextDouble() * 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress;
}
