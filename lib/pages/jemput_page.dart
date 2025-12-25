import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';
import '../services/pickup/pickup_service.dart';

// Pickup button states
enum PickupButtonState { idle, queued, called, sending }

// ============================================
// PICKUP DASHBOARD PAGE
// ============================================
class PickupDashboardPage extends StatefulWidget {
  const PickupDashboardPage({super.key});

  @override
  State<PickupDashboardPage> createState() => _PickupDashboardPageState();
}

class _PickupDashboardPageState extends State<PickupDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _colorController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _buttonColorAnimation;

  final AuthService _authService = AuthService();
  final PickupService _pickupService = PickupService();

  // Pickup state management
  PickupButtonState _buttonState = PickupButtonState.idle;
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  // Connection status monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  // Static flag to track if unstable connection bottomsheet has been shown this session
  // This ensures the bottomsheet only appears once per app lifecycle
  static bool _hasShownUnstableConnectionBottomSheet = false;

  // Data siswa dari hasil login
  String get studentName => _authService.currentUser?.displayName ?? "Siswa";
  String get studentClass =>
      "Kelas ${_authService.currentUser?.namaKelas ?? ""}";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _buttonColorAnimation =
        ColorTween(
          begin: AppColors.primary,
          end: const Color(0xFFF59E0B),
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    // Start polling for status
    _checkPickupStatus();
    _startPolling();

    // Initialize connectivity monitoring
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _colorController.dispose();
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Initialize connectivity check
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (!mounted) return;
    final wasConnected = _isConnected;
    setState(() {
      _isConnected =
          result.isNotEmpty && !result.contains(ConnectivityResult.none);
    });

    // Show bottom sheet when connection becomes unstable (only once per app session)
    if (wasConnected &&
        !_isConnected &&
        !_hasShownUnstableConnectionBottomSheet) {
      _hasShownUnstableConnectionBottomSheet = true;
      _showUnstableConnectionBottomSheet();
    }
  }

  // Show bottom sheet for unstable connection
  void _showUnstableConnectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444), width: 3),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Jaringan Anda tidak stabil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jaringan tidak stabil dapat menyebabkan kegagalan pengiriman data Ananda menuju server kami',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  // Show bottom sheet for stable connection
  void _showStableConnectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF22C55E), width: 3),
              ),
              child: const Icon(
                Icons.wifi_rounded,
                color: Color(0xFF22C55E),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Koneksi Anda stabil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kami mendeteksi koneksi Anda stabil sehingga data Ananda terkirim sempurna menuju server kami',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  // Handle connection status icon tap
  void _handleConnectionStatusTap() {
    if (_isConnected) {
      _showStableConnectionBottomSheet();
    } else {
      _showUnstableConnectionBottomSheet();
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPickupStatus();
    });
  }

  Future<void> _checkPickupStatus() async {
    if (_authService.currentUser == null) return;

    final status = await _pickupService.getPickupStatus(
      _authService.currentUser!.id,
    );
    if (status == null || !mounted) return;

    setState(() {
      if (status.isQueued) {
        _setButtonState(PickupButtonState.queued);
        _cooldownSeconds = 0;
      } else if ((status.isCalled || status.inCooldown) &&
          status.cooldownRemainingSeconds > 0) {
        // Only show TUNGGU state if there's actual cooldown time remaining
        _setButtonState(PickupButtonState.called);
        _cooldownSeconds = status.cooldownRemainingSeconds;
        _startCooldownTimer();
      } else {
        // IDLE - no active request or cooldown expired
        _setButtonState(PickupButtonState.idle);
        _cooldownSeconds = 0;
        _cooldownTimer?.cancel();
      }
    });
  }

  void _setButtonState(PickupButtonState newState) {
    if (_buttonState == newState) return;

    final wasIdle = _buttonState == PickupButtonState.idle;
    final wasSending = _buttonState == PickupButtonState.sending;
    _buttonState = newState;

    // Trigger color animation
    if (newState == PickupButtonState.idle) {
      _colorController.reverse();
    } else if (wasIdle || wasSending) {
      // Animate to yellow when transitioning from idle OR from sending
      _colorController.forward();
    }
  }

  void _startCooldownTimer() {
    // Cancel existing timer if any
    _cooldownTimer?.cancel();

    // Only start timer if there are seconds remaining
    if (_cooldownSeconds <= 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
          _setButtonState(PickupButtonState.idle);
          _cooldownSeconds = 0;
        }
      });
    });
  }

  String _formatCooldown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _handleButtonTap() {
    switch (_buttonState) {
      case PickupButtonState.idle:
        _showPickupBottomSheet();
        break;
      case PickupButtonState.queued:
        _showQueuedBottomSheet();
        break;
      case PickupButtonState.called:
        _showWaitBottomSheet();
        break;
      case PickupButtonState.sending:
        // Do nothing - button is disabled during sending
        break;
    }
  }

  void _showQueuedBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 3),
              ),
              child: const Icon(
                Icons.hourglass_top,
                color: Color(0xFFF59E0B),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Antre Pemanggilan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pemanggilan Ananda masih dalam antrean, silahkan tunggu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  void _showWaitBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 3),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Color(0xFFF59E0B),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tunggu Sebentar Lagi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ananda mungkin sedang perjalanan menuju Lobby. Tunggu ${_formatCooldown(_cooldownSeconds)} untuk memanggil Ananda kembali.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPickupBottomSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: Material(
              color: Colors.transparent,
              child: PickupBottomSheet(
                onSendingStateChange: (isSending, {bool? success}) {
                  setState(() {
                    if (isSending) {
                      _buttonState = PickupButtonState.sending;
                    } else if (success == true) {
                      // Request success - directly set to queued state
                      _setButtonState(PickupButtonState.queued);
                    } else {
                      // Request failed - return to idle
                      _setButtonState(PickupButtonState.idle);
                    }
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Background color based on state
    final bgColor = _buttonState == PickupButtonState.idle
        ? AppColors.background
        : const Color(0xFFFFFBEB); // Light yellow for queued/called/sending

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Header dengan profil siswa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryLight,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: AppColors.primaryLighter,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            studentName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            studentClass,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleConnectionStatusTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isConnected
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _isConnected
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: _isConnected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Guru Penjaga Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShadcnCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_pin_rounded,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saat ini guru yang bertugas',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Siri Rofikah S.Pd',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Main Pickup Button (dengan animasi)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating dashed circle
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotateController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(260, 260),
                                    painter: DashedCirclePainter(
                                      color: AppColors.border,
                                      strokeWidth: 2,
                                      dashLength: 8,
                                      gapLength: 6,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Inner rotating dashed circle (reverse)
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: -_rotateController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(230, 230),
                                    painter: DashedCirclePainter(
                                      color: AppColors.primaryLight.withValues(
                                        alpha: 0.4,
                                      ),
                                      strokeWidth: 1.5,
                                      dashLength: 12,
                                      gapLength: 8,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Main button with pulse and color animation
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _pulseAnimation,
                                _colorController,
                              ]),
                              builder: (context, child) {
                                final color =
                                    _buttonColorAnimation.value ??
                                    AppColors.primary;
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: AnimatedScaleOnTap(
                                    onTap: _handleButtonTap,
                                    scaleDown: 0.92,
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.card,
                                        border: Border.all(
                                          color: color,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.25),
                                            blurRadius: 30,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color: color.withOpacity(0.1),
                                            blurRadius: 60,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Only show icon for JEMPUT and ANTRE states
                                          if (_buttonState ==
                                                  PickupButtonState.idle ||
                                              _buttonState ==
                                                  PickupButtonState.queued) ...[
                                            Icon(
                                              _buttonState ==
                                                      PickupButtonState.idle
                                                  ? Icons.directions_car_rounded
                                                  : Icons.hourglass_top_rounded,
                                              color: color,
                                              size: 42,
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          Text(
                                            _buttonState ==
                                                    PickupButtonState.idle
                                                ? 'JEMPUT'
                                                : _buttonState ==
                                                      PickupButtonState.queued
                                                ? 'ANTRE'
                                                : _buttonState ==
                                                      PickupButtonState.sending
                                                ? 'MENGIRIM'
                                                : 'TUNGGU',
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          if (_buttonState ==
                                              PickupButtonState.queued) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Dalam antrean',
                                              style: TextStyle(
                                                color: color.withOpacity(0.7),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                          if (_buttonState ==
                                              PickupButtonState.sending) ...[
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(color),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Mengirim data..',
                                              style: TextStyle(
                                                color: color.withOpacity(0.7),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                          if (_buttonState ==
                                                  PickupButtonState.called &&
                                              _cooldownSeconds > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatCooldown(_cooldownSeconds),
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom hint - dynamic based on state
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _buttonState == PickupButtonState.idle
                          ? Icons.touch_app_outlined
                          : _buttonState == PickupButtonState.queued
                          ? Icons.hourglass_empty
                          : Icons.directions_walk,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _buttonState == PickupButtonState.idle
                          ? 'Tekan tombol untuk meminta jemput'
                          : _buttonState == PickupButtonState.queued
                          ? 'Murid sedang antrean pemanggilan'
                          : 'Ananda sedang menuju lobby',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // Close AnimatedContainer
    );
  }
}

// ============================================
// DASHED CIRCLE PAINTER
// ============================================
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashLength + gapLength)) / radius;
      final sweepAngle = dashLength / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// PICKUP BOTTOM SHEET
// ============================================
class PickupBottomSheet extends StatefulWidget {
  final Function(bool isSending, {bool? success})? onSendingStateChange;

  const PickupBottomSheet({super.key, this.onSendingStateChange});

  @override
  State<PickupBottomSheet> createState() => _PickupBottomSheetState();
}

class _PickupBottomSheetState extends State<PickupBottomSheet> {
  String _selectedPicker = 'ayah';
  String _selectedOjek = 'gojek';
  String _selectedArrival = 'tiba'; // 'tiba' or 'akan_tiba'
  TimeOfDay? _estimatedTime;
  final TextEditingController _otherPersonController = TextEditingController();
  final TextEditingController _ojekLainnyaController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Services
  final PickupService _pickupService = PickupService();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _otherPersonController.dispose();
    _ojekLainnyaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _estimatedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _estimatedTime = picked;
      });
    }
  }

  // Helper to get penjemput detail based on selection
  String? _getPenjemputDetail() {
    if (_selectedPicker == 'ojek') {
      if (_selectedOjek == 'lainnya') {
        return _ojekLainnyaController.text.isNotEmpty
            ? _ojekLainnyaController.text
            : null;
      }
      return _selectedOjek; // gojek, grab, maxim
    } else if (_selectedPicker == 'lainnya') {
      return _otherPersonController.text.isNotEmpty
          ? _otherPersonController.text
          : null;
    }
    return null;
  }

  // Helper to format TimeOfDay to HH:mm format
  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitRequest() async {
    // Check if user is logged in
    if (_authService.currentUser == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Silakan login terlebih dahulu'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Notify parent that we're sending
    widget.onSendingStateChange?.call(true, success: null);

    // Close bottom sheet first so user can see the 'MENGIRIM' state on main button
    Navigator.pop(context);

    // Call API to submit pickup request
    final result = await _pickupService.requestPickup(
      siswaId: _authService.currentUser!.id,
      penjemput: _selectedPicker,
      penjemputDetail: _getPenjemputDetail(),
      estimasiWaktu: _selectedArrival,
      waktuEstimasi: _selectedArrival == 'akan_tiba'
          ? _formatTimeOfDay(_estimatedTime)
          : null,
    );

    // Notify parent that sending is complete with success status
    widget.onSendingStateChange?.call(false, success: result.success);

    // Show result snackbar (using navigatorKey or root context since this widget is unmounted)
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.success
                    ? 'Permintaan jemput berhasil! Nomor antrian: ${result.nomorAntrian}'
                    : result.message,
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? AppColors.primary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  'Permintaan Penjemputan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Section 1: Dijemput oleh siapa
              _buildLabel('Ananda dijemput oleh siapa?'),
              const SizedBox(height: 10),
              _buildSegmentedButton(),

              // Ojek sub-selector
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedPicker == 'ojek'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildOjekSubSelector(),
                      )
                    : const SizedBox.shrink(),
              ),

              // Ojek lainnya input
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedPicker == 'ojek' && _selectedOjek == 'lainnya'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTextField(
                          controller: _ojekLainnyaController,
                          hint: 'Nama ojek online lainnya',
                          icon: Icons.two_wheeler,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Other person input
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedPicker == 'lainnya'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTextField(
                          controller: _otherPersonController,
                          hint: 'Nama orang yang menjemput',
                          icon: Icons.person_outline,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Section 2: Estimasi waktu
              _buildLabel('Estimasi Anda sampai sekolah?'),
              const SizedBox(height: 10),
              _buildArrivalSegmentedButton(),

              // Time input for "akan tiba"
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedArrival == 'akan_tiba'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTimeSelector(),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  int get _pickerIndex {
    switch (_selectedPicker) {
      case 'ayah':
        return 0;
      case 'ibu':
        return 1;
      case 'ojek':
        return 2;
      case 'lainnya':
        return 3;
      default:
        return 0;
    }
  }

  final List<String> _pickerOptions = ['ayah', 'ibu', 'ojek', 'lainnya'];

  void _handlePickerSwipe(DragEndDetails details, double containerWidth) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      // Swipe detected
      if (velocity > 0 && _pickerIndex > 0) {
        // Swipe right - go to previous
        setState(() => _selectedPicker = _pickerOptions[_pickerIndex - 1]);
      } else if (velocity < 0 && _pickerIndex < 3) {
        // Swipe left - go to next
        setState(() => _selectedPicker = _pickerOptions[_pickerIndex + 1]);
      }
    }
  }

  void _handlePickerDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 4;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 3);

    if (newIndex != _pickerIndex) {
      setState(() => _selectedPicker = _pickerOptions[newIndex]);
    }
  }

  Widget _buildSegmentedButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / 4;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _handlePickerDragUpdate(details, constraints.maxWidth),
            onHorizontalDragEnd: (details) =>
                _handlePickerSwipe(details, constraints.maxWidth),
            child: Stack(
              children: [
                // Sliding indicator with bounce
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: _pickerIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Items
                Row(
                  children: [
                    _buildSegmentItem('ayah', 'Ayah', Icons.man),
                    _buildSegmentItem('ibu', 'Ibu', Icons.woman),
                    _buildSegmentItem('ojek', 'Ojek', Icons.two_wheeler),
                    _buildSegmentItem('lainnya', 'Lainnya', Icons.people),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOjekSubSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildOjekItem('gojek', 'Gojek'),
              _buildOjekItem('grab', 'Grab'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildOjekItem('maxim', 'Maxim'),
              _buildOjekItem('lainnya', 'Lainya'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOjekItem(String value, String label) {
    final isSelected = _selectedOjek == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedOjek = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem(String value, String label, IconData icon) {
    final isSelected = _selectedPicker == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPicker = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'MaterialIcons',
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _arrivalIndex {
    return _selectedArrival == 'tiba' ? 0 : 1;
  }

  final List<String> _arrivalOptions = ['tiba', 'akan_tiba'];

  void _handleArrivalSwipe(DragEndDetails details, double containerWidth) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      // Swipe detected
      if (velocity > 0 && _arrivalIndex > 0) {
        // Swipe right - go to previous
        setState(() => _selectedArrival = _arrivalOptions[_arrivalIndex - 1]);
      } else if (velocity < 0 && _arrivalIndex < 1) {
        // Swipe left - go to next
        setState(() => _selectedArrival = _arrivalOptions[_arrivalIndex + 1]);
      }
    }
  }

  void _handleArrivalDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 2;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 1);

    if (newIndex != _arrivalIndex) {
      setState(() => _selectedArrival = _arrivalOptions[newIndex]);
    }
  }

  Widget _buildArrivalSegmentedButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / 2;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _handleArrivalDragUpdate(details, constraints.maxWidth),
            onHorizontalDragEnd: (details) =>
                _handleArrivalSwipe(details, constraints.maxWidth),
            child: Stack(
              children: [
                // Sliding indicator with bounce
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: _arrivalIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Items
                Row(
                  children: [
                    _buildArrivalItem(
                      'tiba',
                      'Tiba di sekolah',
                      Icons.check_circle_outline,
                    ),
                    _buildArrivalItem(
                      'akan_tiba',
                      'Akan tiba...',
                      Icons.schedule,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArrivalItem(String value, String label, IconData icon) {
    final isSelected = _selectedArrival == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedArrival = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.textMuted, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _estimatedTime != null
                ? AppColors.primary
                : AppColors.border,
            width: _estimatedTime != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _estimatedTime != null
                  ? _estimatedTime!.format(context)
                  : 'Pilih waktu estimasi',
              style: TextStyle(
                fontSize: 14,
                color: _estimatedTime != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: _estimatedTime != null
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SwipeToConfirm(
      text: 'Geser untuk panggil',
      onConfirm: _submitRequest,
    );
  }
}

// ============================================
// SWIPE TO CONFIRM WIDGET
// ============================================
class SwipeToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;

  const SwipeToConfirm({
    super.key,
    required this.text,
    required this.onConfirm,
  });

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  double _containerWidth = 0;
  bool _isConfirmed = false;
  late AnimationController _shimmerController;

  static const double _thumbSize = 52;
  static const double _padding = 4;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  double get _maxDragDistance => _containerWidth - _thumbSize - (_padding * 2);
  double get _dragPercentage => _maxDragDistance > 0
      ? (_dragPosition / _maxDragDistance).clamp(0.0, 1.0)
      : 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isConfirmed) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(
        0.0,
        _maxDragDistance,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isConfirmed) return;

    if (_dragPercentage > 0.85) {
      // Konfirmasi berhasil
      setState(() {
        _dragPosition = _maxDragDistance;
        _isConfirmed = true;
      });

      // Haptic feedback dan panggil callback
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onConfirm();
      });
    } else {
      // Kembali ke posisi awal dengan animasi bounce
      _animateBack();
    }
  }

  void _animateBack() {
    const duration = Duration(milliseconds: 400);
    final startPosition = _dragPosition;

    Future<void> animate() async {
      const steps = 20;
      for (int i = 0; i <= steps; i++) {
        await Future.delayed(duration ~/ steps);
        if (!mounted) return;

        // Kurva easeOutBack untuk efek bounce
        final t = i / steps;
        final curve = Curves.easeOutBack.transform(t);

        setState(() {
          _dragPosition = startPosition * (1 - curve);
        });
      }
    }

    animate();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: _isConfirmed ? Colors.green.shade500 : AppColors.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isConfirmed
                  ? Colors.green.shade500
                  : AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isConfirmed
                    ? Colors.green.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition + _thumbSize + _padding,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isConfirmed
                        ? [Colors.green.shade500, Colors.green.shade400]
                        : [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primaryLight.withValues(alpha: 0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),

              // Text dengan shimmer effect
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isConfirmed ? 0 : (1 - _dragPercentage * 0.5),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              AppColors.textMuted,
                              AppColors.primary,
                              AppColors.textMuted,
                            ],
                            stops: [
                              (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                              _shimmerController.value,
                              (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Confirmed text - show 'Memproses..'
              if (_isConfirmed)
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Memproses..',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // Draggable thumb
              Positioned(
                left: _padding + _dragPosition,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: _isConfirmed ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isConfirmed
                                        ? Colors.green
                                        : AppColors.primary)
                                    .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isConfirmed
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                        color: _isConfirmed
                            ? Colors.green.shade500
                            : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
