import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAndNavigate();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/images/splash_video.mp4',
    );

    try {
      await _videoController.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _videoController.setLooping(false);
        _videoController.setVolume(1.0);
        _videoController.play();

        // Listen for video completion
        _videoController.addListener(_videoListener);
      }
    } catch (e) {
      // If video fails to load, navigate after a delay
      debugPrint('Video initialization error: $e');
      if (mounted) {
        // Wait a bit for initialization to complete, then navigate
        Future.delayed(const Duration(seconds: 2), () {
          if (!_hasNavigated && mounted) {
            _navigateToNext();
          }
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController.value.isCompleted && !_hasNavigated) {
      _navigateToNext();
    }
  }

  Future<void> _initializeAndNavigate() async {
    // StorageService and UserTypeController are already initialized in main()
    // Just precache the logo so the LoginScreen renders without a jank frame
    if (mounted) {
      await precacheImage(
        const AssetImage('assets/images/app_logo.jpeg'),
        context,
      );
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Wait for the current frame to finish before navigating
    // so the transition starts from a fully painted frame (no jank)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.navigateToAndRemoveUntil(const LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Video Player - fills the screen
          if (_isInitialized && _videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            // White screen while video initializes — matches native splash background
            // to eliminate the visible flash during the native→Flutter transition
            const SizedBox.expand(),
        ],
      ),
    );
  }

}

