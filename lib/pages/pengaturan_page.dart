import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

// ============================================
// PENGATURAN PAGE
// ============================================
class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage>
    with WidgetsBindingObserver {
  bool _matikanOptimalisasiBaterai = false;
  bool _kurangiAnimasi = false;
  bool _isCheckingBattery = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBatteryOptimizationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when app lifecycle state changes (e.g., returning from settings)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check battery optimization when user returns to app
      _checkBatteryOptimizationStatus();
    }
  }

  /// Check if battery optimization is disabled for this app
  Future<void> _checkBatteryOptimizationStatus() async {
    setState(() => _isCheckingBattery = true);

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (mounted) {
        setState(() {
          // Toggle ON = battery optimization is IGNORED (not optimized = good for app)
          _matikanOptimalisasiBaterai = status.isGranted;
          _isCheckingBattery = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      if (mounted) {
        setState(() => _isCheckingBattery = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Section: Optimalisasi
                    _buildSectionHeader('Optimalisasi'),
                    const SizedBox(height: 12),

                    _buildBatteryOptimizationCard(),

                    const SizedBox(height: 24),

                    // Section: Visual
                    _buildSectionHeader('Visual'),
                    const SizedBox(height: 12),

                    _buildSettingCard(
                      icon: Icons.animation_rounded,
                      title: 'Kurangi Gestur Animasi',
                      subtitle:
                          'Matikan semua animasi dalam aplikasi, cocok untuk perangkat spesifikasi rendah',
                      value: _kurangiAnimasi,
                      onChanged: (value) {
                        setState(() {
                          _kurangiAnimasi = value;
                        });
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build battery optimization card with status indicator
  Widget _buildBatteryOptimizationCard() {
    return ShadcnCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _matikanOptimalisasiBaterai
                      ? AppColors.primaryLighter
                      : AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.battery_saver_rounded,
                  color: _matikanOptimalisasiBaterai
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Matikan Optimalisasi Baterai',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Agar aplikasi berjalan dengan lancar, matikan optimalisasi baterai pada aplikasi agar tidak dimatikan oleh sistem',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _isCheckingBattery
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch.adaptive(
                      value: _matikanOptimalisasiBaterai,
                      onChanged: (value) {
                        if (!_matikanOptimalisasiBaterai) {
                          // Only allow turning ON (disabling optimization)
                          _showBatteryOptimizationInfo();
                        } else {
                          // If already disabled, show info that they need to enable it from settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Untuk mengaktifkan kembali optimalisasi baterai, buka Pengaturan > Baterai > Optimalisasi Baterai',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primaryLighter,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(width: 3, height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ShadcnCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: value
                      ? AppColors.primaryLighter
                      : AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: value ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLighter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBatteryOptimizationInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.battery_saver_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lanjut ke Pengaturan?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Anda akan diarahkan ke pengaturan sistem untuk menonaktifkan optimalisasi baterai pada aplikasi ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Request permission to ignore battery optimization
                  await Permission.ignoreBatteryOptimizations.request();
                  // Status will be updated via didChangeAppLifecycleState when user returns
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Buka Pengaturan',
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
}
