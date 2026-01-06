import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_page.dart';

/// Onboarding Page - Shows only once after first install
/// Page 1: Welcome with image
/// Page 2: Permission requests (notification & precise location)
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Permission states
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _isPreciseLocation = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Check current permission status
  Future<void> _checkCurrentPermissions() async {
    final notifStatus = await Permission.notification.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    setState(() {
      _notificationGranted = notifStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
    });

    // Check if precise location is enabled
    if (_locationGranted) {
      await _checkPreciseLocation();
    }
  }

  /// Check if precise location is enabled
  Future<void> _checkPreciseLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // Consider precise if accuracy is under 100 meters
      setState(() {
        _isPreciseLocation = position.accuracy < 100;
      });
    } catch (e) {
      debugPrint('Error checking location precision: $e');
      setState(() {
        _isPreciseLocation = false;
      });
    }
  }

  /// Request notification permission
  Future<void> _requestNotificationPermission() async {
    if (_isRequestingPermission) return;

    setState(() => _isRequestingPermission = true);

    try {
      final status = await Permission.notification.request();
      setState(() {
        _notificationGranted = status.isGranted;
      });
    } finally {
      setState(() => _isRequestingPermission = false);
    }
  }

  /// Show bottom sheet explaining location permission
  void _showLocationPermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 36,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Lokasi Presisi Dibutuhkan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Untuk memastikan penjemputan Ananda berjalan dengan akurat, kami memerlukan akses lokasi presisi (tepat) dari perangkat Anda.\n\nPastikan untuk mengaktifkan "Lokasi Presisi" atau "Precise Location" saat diminta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Request permission button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _requestLocationPermission();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Izinkan Lokasi Presisi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Request location permission with precise location enforcement
  Future<void> _requestLocationPermission() async {
    if (_isRequestingPermission) return;

    setState(() => _isRequestingPermission = true);

    try {
      // First, request location permission
      final status = await Permission.locationWhenInUse.request();

      if (status.isGranted) {
        setState(() => _locationGranted = true);

        // Check if precise location is enabled
        await _checkPreciseLocation();

        // If not precise, show dialog to guide user
        if (!_isPreciseLocation && mounted) {
          await _showPreciseLocationDialog();
        }
      } else if (status.isPermanentlyDenied) {
        // Guide user to app settings
        if (mounted) {
          await _showPermissionDeniedDialog('Lokasi');
        }
      }
    } finally {
      setState(() => _isRequestingPermission = false);
    }
  }

  /// Show dialog explaining why precise location is needed
  Future<void> _showPreciseLocationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.location_on, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Lokasi Presisi Diperlukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          'Untuk memastikan penjemputan yang akurat, aplikasi memerlukan izin lokasi presisi (tepat).\n\nMohon aktifkan "Lokasi Presisi" atau "Precise Location" di pengaturan aplikasi.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );

    if (result == true) {
      await Geolocator.openLocationSettings();
      // Re-check after returning from settings
      await Future.delayed(const Duration(seconds: 1));
      await _checkPreciseLocation();
    }
  }

  /// Show dialog for permanently denied permission
  Future<void> _showPermissionDeniedDialog(String permissionName) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Izin $permissionName Ditolak'),
        content: Text(
          'Izin $permissionName diperlukan untuk aplikasi ini. '
          'Mohon aktifkan di pengaturan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  /// Complete onboarding and navigate to login page
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_initial_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// Go to next page
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _buildPageIndicator(0),
                  const SizedBox(width: 8),
                  _buildPageIndicator(1),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [_buildWelcomePage(), _buildPermissionsPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Page 1: Welcome Page
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'lib/assets/page-1-onboarding.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Welcome text
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const Text(
                  'Assalamualaikum Ayah dan Bunda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kami siap membantu Anda dalam proses penjemputan Ananda dengan cepat dan mudah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                // const SizedBox(height: 24),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Page 2: Permissions Page
  Widget _buildPermissionsPage() {
    final allPermissionsGranted = _notificationGranted && _locationGranted;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Title
          const Text(
            'Perizinan Aplikasi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Untuk melanjutkan silahkan berikan kami perizinan sebagai mana berikut:',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Permission Cards
          _buildPermissionCard(
            icon: Icons.notifications_rounded,
            iconColor: Colors.amber,
            iconBgColor: Colors.amber.shade50,
            title: 'Notifikasi',
            description:
                'Untuk menerima pemberitahuan jadwal penjemputan Ananda',
            isGranted: _notificationGranted,
            onTap: _requestNotificationPermission,
          ),

          const SizedBox(height: 16),

          _buildPermissionCard(
            icon: Icons.location_on_rounded,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.shade50,
            title: 'Lokasi Presisi',
            description: _isPreciseLocation
                ? 'Lokasi presisi aktif untuk penjemputan yang akurat'
                : 'Untuk verifikasi lokasi penjemputan secara akurat',
            isGranted: _locationGranted,
            showPreciseWarning: _locationGranted && !_isPreciseLocation,
            onTap: _showLocationPermissionBottomSheet,
          ),

          const Spacer(),

          // Info text
          if (!allPermissionsGranted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap pada kartu di atas untuk memberikan izin',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Buttons row
          Row(
            children: [
              // Back button
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Continue/Start button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: allPermissionsGranted ? _completeOnboarding : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    allPermissionsGranted ? 'Mulai' : 'Berikan Izin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required bool isGranted,
    bool showPreciseWarning = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isRequestingPermission ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGranted ? Colors.green.shade50 : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted
                ? (showPreciseWarning
                      ? Colors.orange.shade200
                      : Colors.green.shade200)
                : AppColors.border,
            width: isGranted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGranted ? Colors.green.shade100 : iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGranted ? Icons.check_rounded : icon,
                color: isGranted ? Colors.green.shade600 : iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isGranted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: showPreciseWarning
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            showPreciseWarning ? 'Tidak Presisi' : 'Diizinkan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: showPreciseWarning
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow or loading
            if (_isRequestingPermission)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else if (!isGranted)
              Icon(Icons.chevron_right, color: AppColors.textMuted)
            else if (showPreciseWarning)
              Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade600,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
