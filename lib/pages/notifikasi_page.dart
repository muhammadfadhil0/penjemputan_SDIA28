import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/notification_settings_model.dart';
import '../services/auth/auth_service.dart';
import '../services/jadwal/jadwal_service.dart';
import '../services/jadwal/schedule_change_monitor.dart';
import 'pengaturan_page.dart';

// ============================================
// NOTIFIKASI PAGE
// ============================================
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  bool _pengingatPenjemputan = false;
  bool _pengingatPerubahanJadwal = false;
  int _menitSebelumPulang = 15; // Default 15 menit
  bool _isLoading = true;
  String _notificationSound = 'Bell';

  // Developer mode
  int _headerTapCount = 0;
  bool _developerModeEnabled = false;

  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final JadwalService _jadwalService = JadwalService();
  final ScheduleChangeMonitor _scheduleChangeMonitor = ScheduleChangeMonitor();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Memuat pengaturan notifikasi dari storage
  Future<void> _loadSettings() async {
    final settings = await _notificationService.loadSettings();
    if (mounted) {
      setState(() {
        _pengingatPenjemputan = settings.pickupReminderEnabled;
        _pengingatPerubahanJadwal = settings.scheduleChangeEnabled;
        _menitSebelumPulang = settings.minutesBeforePickup;
        _notificationSound = settings.notificationSound;
        _isLoading = false;
      });

      // Start monitoring jika pengingat perubahan jadwal aktif
      if (settings.scheduleChangeEnabled) {
        _scheduleChangeMonitor.startMonitoring();
      }
    }
  }

  /// Menyimpan pengaturan dan menjadwalkan/membatalkan notifikasi
  Future<void> _saveSettingsAndSchedule() async {
    debugPrint('NotifikasiPage: _saveSettingsAndSchedule called');

    final settings = NotificationSettings(
      pickupReminderEnabled: _pengingatPenjemputan,
      minutesBeforePickup: _menitSebelumPulang,
      scheduleChangeEnabled: _pengingatPerubahanJadwal,
      notificationSound: _notificationSound,
    );

    // Simpan settings
    await _notificationService.saveSettings(settings);
    debugPrint('NotifikasiPage: Settings saved');

    if (_pengingatPenjemputan) {
      debugPrint('NotifikasiPage: Pengingat aktif, requesting permission...');

      // Request permission jika belum
      final hasPermission = await _notificationService.requestPermission();
      debugPrint('NotifikasiPage: Permission result = $hasPermission');

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin notifikasi diperlukan untuk fitur ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      debugPrint('NotifikasiPage: Calling _scheduleNotification...');
      await _scheduleNotification();
      debugPrint('NotifikasiPage: _scheduleNotification completed');
    } else {
      debugPrint('NotifikasiPage: Pengingat nonaktif, cancelling...');
      await _notificationService.cancelPickupNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat penjemputan dinonaktifkan'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  /// Menjadwalkan notifikasi berdasarkan jadwal hari ini
  Future<void> _scheduleNotification() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showDebugSnackbar('Error: User tidak ditemukan');
      return;
    }

    // Guru tidak memiliki kelas, skip
    if (currentUser.kelasId == null) {
      _showDebugSnackbar('Info: Fitur ini khusus untuk siswa');
      return;
    }

    // Clear cache dan ambil jadwal fresh dari server
    _jadwalService.clearCache();

    // Ambil jadwal berdasarkan kelas siswa
    final jadwalResult = await _jadwalService.getJadwalByKelas(
      currentUser.kelasId!,
    );
    if (!jadwalResult.success || jadwalResult.jadwal == null) {
      _showDebugSnackbar(
        'Error: Gagal mengambil jadwal - ${jadwalResult.message}',
      );
      return;
    }

    // Ambil jadwal hari ini
    final todaySchedule = jadwalResult.jadwal!.todaySchedule;
    if (todaySchedule == null) {
      _showDebugSnackbar('Error: Tidak ada jadwal untuk hari ini');
      return;
    }

    if (todaySchedule.isHoliday) {
      _showDebugSnackbar('Info: Hari ini libur, notifikasi tidak dijadwalkan');
      return;
    }

    // Hitung waktu notifikasi untuk debug
    final parts = todaySchedule.jamPulang.split(':');
    final hour = int.tryParse(parts[0]) ?? 14;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    var pickupTime = DateTime(now.year, now.month, now.day, hour, minute);
    final notificationTime = pickupTime.subtract(
      Duration(minutes: _menitSebelumPulang),
    );

    // Jadwalkan notifikasi
    await _notificationService.scheduleDailyPickupNotification(
      pickupTimeString: todaySchedule.jamPulang,
      minutesBefore: _menitSebelumPulang,
      studentName: currentUser.displayName,
    );

    if (mounted) {
      final nowStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final notifStr =
          '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';

      if (notificationTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Waktu notifikasi ($notifStr) sudah lewat! Sekarang: $nowStr',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notifikasi dijadwalkan: $notifStr (pulang ${todaySchedule.jamPulang})',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showDebugSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Handler untuk tap pada header "Notifikasi"
  void _onHeaderTap() {
    _headerTapCount++;

    if (_headerTapCount >= 5) {
      _headerTapCount = 0;

      if (_developerModeEnabled) {
        // Sudah aktif, matikan
        setState(() {
          _developerModeEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu debug disembunyikan'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        // Belum aktif, tampilkan bottom sheet
        _showDeveloperModeBottomSheet();
      }
    }
  }

  /// Menampilkan bottom sheet konfirmasi developer mode
  void _showDeveloperModeBottomSheet() {
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
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.code_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aktifkan fitur Developer?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berguna untuk mendebug aplikasi perihal notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _developerModeEnabled = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🧑‍💻 Selamat datang Developer!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
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
                  'Saya Developer',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                  GestureDetector(
                    onTap: _onHeaderTap,
                    child: const Text(
                      'Notifikasi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

                    // Section Header
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Pengaturan Notifikasi',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Pengingat Penjemputan Toggle
                    _buildNotificationCard(
                      icon: Icons.access_time_rounded,
                      title: 'Pengingat Penjemputan',
                      subtitle: 'Dapatkan pengingat untuk menjemput Ananda',
                      value: _pengingatPenjemputan,
                      onChanged: (value) {
                        setState(() {
                          _pengingatPenjemputan = value;
                        });
                        _saveSettingsAndSchedule();
                      },
                    ),

                    // Waktu pengingat (muncul jika pengingat penjemputan aktif)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: _pengingatPenjemputan
                          ? Column(children: [_buildTimeSelector()])
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 12),

                    // Pengingat Perubahan Jadwal Toggle
                    _buildNotificationCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Pengingat Perubahan Jadwal',
                      subtitle:
                          'Dapatkan notifikasi saat jadwal kepulangan berubah',
                      value: _pengingatPerubahanJadwal,
                      onChanged: (value) async {
                        // Jika ingin mengaktifkan, cek dulu status battery optimization
                        if (value) {
                          final batteryStatus = await Permission
                              .ignoreBatteryOptimizations
                              .status;
                          if (!batteryStatus.isGranted) {
                            // Battery optimization masih aktif, tampilkan bottom sheet
                            if (mounted) {
                              _showBatteryOptimizationRequiredBottomSheet();
                            }
                            return; // Batalkan toggle
                          }
                        }

                        setState(() {
                          _pengingatPerubahanJadwal = value;
                        });

                        // Start/stop monitoring berdasarkan toggle
                        if (value) {
                          _scheduleChangeMonitor.startMonitoring();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pengingat perubahan jadwal diaktifkan',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } else {
                          _scheduleChangeMonitor.stopMonitoring();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pengingat perubahan jadwal dinonaktifkan',
                              ),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        }

                        _saveSettingsAndSchedule();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section Header - Debug (hidden by default)
                    if (_developerModeEnabled) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Debug (Developer)',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Test Notification Button
                      GestureDetector(
                        onTap: () async {
                          await _notificationService.showTestNotification();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifikasi test dikirim!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        child: ShadcnCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kirim Notifikasi Test',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap untuk menguji apakah notifikasi berfungsi',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textMuted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Test Schedule Change Notification Button
                      GestureDetector(
                        onTap: () async {
                          await _notificationService
                              .showScheduleChangeNotification();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notifikasi perubahan jadwal test dikirim!',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        child: ShadcnCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Test Notifikasi Perubahan Jadwal',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap untuk test notifikasi perubahan jadwal',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textMuted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Force Check Schedule Changes Button
                      GestureDetector(
                        onTap: () async {
                          // Reset last seen dan mulai ulang monitoring
                          await _scheduleChangeMonitor.resetLastSeen();
                          _scheduleChangeMonitor.stopMonitoring();
                          await _scheduleChangeMonitor.startMonitoring();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pengecekan jadwal dimulai ulang!',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        child: ShadcnCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cek Jadwal Sekarang',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Cek ulang perubahan jadwal skearang',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textMuted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ], // Close if (_developerModeEnabled)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ShadcnCard(
      padding: const EdgeInsets.all(16),
      child: Row(
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLighter,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ShadcnCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ingatkan sebelum jadwal pulang',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTimeOption(5),
                const SizedBox(width: 8),
                _buildTimeOption(10),
                const SizedBox(width: 8),
                _buildTimeOption(15),
                const SizedBox(width: 8),
                _buildTimeOption(30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOption(int menit) {
    final isSelected = _menitSebelumPulang == menit;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _menitSebelumPulang = menit;
          });
          _saveSettingsAndSchedule();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$menit',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'menit',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan bottom sheet yang menginformasikan perlu menonaktifkan optimalisasi baterai
  void _showBatteryOptimizationRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.battery_alert_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fitur ini membutuhkan fungsi lain berjalan agar tetap aktif',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fitur ini membuat aplikasi mengecek apakah ada perubahan jadwal di server kami selama 10 menit, diperlukan mengaktifkan fitur Nonaktifkan Optimalisasi Baterai',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PengaturanPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buka Pengaturan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
