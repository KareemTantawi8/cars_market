import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/extensions.dart';
import 'login_screen.dart';

/// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startVideo();
  }

  Future<void> _startVideo() async {
    final c = VideoPlayerController.asset('assets/images/splash_video.mp4');
    _controller = c;

    try {
      await c.initialize().timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => _videoReady = true);
      c.setLooping(false);
      c.play();
      c.addListener(() {
        if (c.value.position >= c.value.duration && c.value.duration > Duration.zero) {
          _navigate();
        }
      });
    } catch (_) {
      // Video failed to load — navigate after a brief pause
      await Future.delayed(const Duration(seconds: 2));
      _navigate();
    }
  }

  void _navigate() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.navigateToAndRemoveUntil(const LoginScreen());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.white,
      body: (c != null && _videoReady)
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

