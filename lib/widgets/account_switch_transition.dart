import 'package:flutter/material.dart';

/// Helper class untuk trigger animasi switch akun di seluruh app
class AccountSwitchAnimationController extends ChangeNotifier {
  static final AccountSwitchAnimationController _instance =
      AccountSwitchAnimationController._internal();
  factory AccountSwitchAnimationController() => _instance;
  AccountSwitchAnimationController._internal();

  bool _shouldAnimate = false;
  bool get shouldAnimate => _shouldAnimate;

  /// Trigger animasi switch
  void triggerAnimation() {
    _shouldAnimate = true;
    notifyListeners();

    // Reset setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 800), () {
      _shouldAnimate = false;
      notifyListeners();
    });
  }

  /// Reset state
  void reset() {
    _shouldAnimate = false;
    notifyListeners();
  }
}

/// Widget wrapper untuk halaman dengan animasi zoom out → fade → zoom in
class AccountSwitchAnimatedPage extends StatefulWidget {
  final Widget child;

  const AccountSwitchAnimatedPage({super.key, required this.child});

  @override
  State<AccountSwitchAnimatedPage> createState() =>
      _AccountSwitchAnimatedPageState();
}

class _AccountSwitchAnimatedPageState extends State<AccountSwitchAnimatedPage>
    with SingleTickerProviderStateMixin {
  final _animationController = AccountSwitchAnimationController();
  late AnimationController _controller;

  // Animasi zoom out (skala mengecil)
  late Animation<double> _zoomOutAnimation;
  // Animasi fade (opacity menurun)
  late Animation<double> _fadeOutAnimation;
  // Animasi zoom in (skala membesar kembali)
  late Animation<double> _zoomInAnimation;
  // Animasi fade in (opacity naik)
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Fase 1: Zoom out dan fade out (0.0 - 0.45)
    _zoomOutAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Fase 2: Zoom in dan fade in (0.45 - 1.0)
    _zoomInAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.addListener(_onAnimationTrigger);
  }

  void _onAnimationTrigger() {
    if (_animationController.shouldAnimate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTrigger);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Determine which phase we're in
        final progress = _controller.value;
        final isZoomingOut = progress <= 0.45;

        double scale;
        double opacity;

        if (isZoomingOut) {
          // Fase 1: Zoom out & fade out
          scale = _zoomOutAnimation.value;
          opacity = _fadeOutAnimation.value;
        } else {
          // Fase 2: Zoom in & fade in
          scale = _zoomInAnimation.value;
          opacity = _fadeInAnimation.value;
        }

        // Jika tidak ada animasi, tampilkan normal
        if (!_controller.isAnimating && _controller.value == 0) {
          return widget.child;
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: widget.child),
        );
      },
    );
  }
}
