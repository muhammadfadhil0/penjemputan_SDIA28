import 'package:flutter/material.dart';
import '../main.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/notification_settings_model.dart';
import '../services/auth/auth_service.dart';
import '../services/jadwal/jadwal_service.dart';

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

  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final JadwalService _jadwalService = JadwalService();

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

    // Clear cache dan ambil jadwal fresh dari server
    _jadwalService.clearCache();

    // Ambil jadwal berdasarkan kelas siswa
    final jadwalResult = await _jadwalService.getJadwalByKelas(
      currentUser.kelasId,
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
                  const Text(
                    'Notifikasi',
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
                      onChanged: (value) {
                        setState(() {
                          _pengingatPerubahanJadwal = value;
                        });
                        _saveSettingsAndSchedule();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section Header - Test
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Test Notifikasi',
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
}
