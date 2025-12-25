import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';

/// Layar alarm fullscreen yang muncul saat waktu penjemputan
class AlarmScreen extends StatefulWidget {
  final String studentName;
  final String pickupTime;
  final String alarmSound; // file name in assets/sounds/ringtone/

  const AlarmScreen({
    super.key,
    required this.studentName,
    required this.pickupTime,
    this.alarmSound = 'Kami Al Azhar',
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _dragOffset = 0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    // Hide system UI for fullscreen effect
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Setup animation for bell icon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Play alarm sound
    _playAlarmSound();
  }

  Future<void> _playAlarmSound() async {
    try {
      // Set to loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Build sound file path from ringtone folder
      final soundFile = 'sounds/ringtone/${widget.alarmSound}.mp3';

      try {
        await _audioPlayer.play(AssetSource(soundFile));
        debugPrint('AlarmScreen: Playing $soundFile');
      } catch (assetError) {
        debugPrint(
          'AlarmScreen: Asset not found, trying uppercase extension - $assetError',
        );
        // Try with uppercase extension
        try {
          final soundFileUpper = 'sounds/ringtone/${widget.alarmSound}.MP3';
          await _audioPlayer.play(AssetSource(soundFileUpper));
          debugPrint('AlarmScreen: Playing $soundFileUpper');
        } catch (e) {
          debugPrint('AlarmScreen: No sound file found, visual only mode');
        }
      }
    } catch (e) {
      debugPrint('AlarmScreen: Error playing sound - $e');
    }
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  void _dismissAlarm() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);

    await _stopAlarm();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dy;
            if (_dragOffset > 0) _dragOffset = 0; // Only allow upward drag
          });
        },
        onVerticalDragEnd: (details) {
          // If dragged up more than 150px, dismiss
          if (_dragOffset < -150) {
            _dismissAlarm();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _dragOffset, 0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated Bell Icon
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'WAKTUNYA JEMPUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Student Name
                  Text(
                    widget.studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Pickup Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.pickupTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Swipe Indicator
                  Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Geser ke atas untuk menonaktifkan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Dismiss Button (alternative to swipe)
                  TextButton(
                    onPressed: _dismissAlarm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'MATIKAN ALARM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
