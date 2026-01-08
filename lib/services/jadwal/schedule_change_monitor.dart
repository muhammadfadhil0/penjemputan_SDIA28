import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/notification_service.dart';
import '../auth/multi_account_service.dart';
import '../settings/settings_sync_service.dart';

/// Model untuk hasil pengecekan perubahan jadwal
class ScheduleChangeResult {
  final bool success;
  final String message;
  final bool hasChanges;
  final String? latestUpdate;

  ScheduleChangeResult({
    required this.success,
    required this.message,
    required this.hasChanges,
    this.latestUpdate,
  });
}

/// Service untuk memonitor perubahan jadwal kelas
/// Melakukan polling periodik dan menampilkan notifikasi jika ada perubahan
/// Mendukung multi-account: cek semua akun yang terdaftar
class ScheduleChangeMonitor {
  // Singleton instance
  static final ScheduleChangeMonitor _instance =
      ScheduleChangeMonitor._internal();
  factory ScheduleChangeMonitor() => _instance;
  ScheduleChangeMonitor._internal();

  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/jadwal';

  // Key untuk SharedPreferences (per-kelas)
  static String _getLastSeenKey(int kelasId) =>
      'schedule_last_seen_update_$kelasId';

  // Interval polling (10 menit)
  static const Duration _pollInterval = Duration(minutes: 10);

  // Timer untuk polling
  Timer? _pollTimer;

  // Flag apakah monitoring aktif
  bool _isMonitoring = false;

  // Dependencies
  final NotificationService _notificationService = NotificationService();
  final MultiAccountService _multiAccountService = MultiAccountService();
  final SettingsSyncService _settingsSyncService = SettingsSyncService();

  /// Memulai monitoring perubahan jadwal
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('ScheduleChangeMonitor: Already monitoring');
      return;
    }

    _isMonitoring = true;
    debugPrint('ScheduleChangeMonitor: Starting monitoring');

    // Inisialisasi notification service
    await _notificationService.initialize();

    // Lakukan pengecekan pertama untuk semua akun
    await _checkAllAccountsForChanges();

    // Set up polling timer
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _checkAllAccountsForChanges();
    });
  }

  /// Menghentikan monitoring
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isMonitoring = false;
    debugPrint('ScheduleChangeMonitor: Stopped monitoring');
  }

  /// Mengecek perubahan jadwal untuk SEMUA akun yang terdaftar
  Future<void> _checkAllAccountsForChanges() async {
    final accounts = _multiAccountService.accounts;

    if (accounts.isEmpty) {
      debugPrint('ScheduleChangeMonitor: No accounts registered');
      return;
    }

    debugPrint('ScheduleChangeMonitor: Checking ${accounts.length} accounts');

    for (final account in accounts) {
      // Cek apakah siswa mengaktifkan schedule change notification
      final settings = await _settingsSyncService.loadSettings(account.id);

      if (!settings.scheduleChangeEnabled) {
        debugPrint(
          'ScheduleChangeMonitor: Skipping ${account.namaPanggilan} (notifications disabled)',
        );
        continue;
      }

      // Cek perubahan untuk kelas siswa ini
      final kelasId = account.kelasId;
      if (kelasId == null) {
        debugPrint(
          'ScheduleChangeMonitor: Skipping ${account.namaPanggilan} (no kelas)',
        );
        continue;
      }

      await _checkForChanges(
        siswaId: account.id,
        kelasId: kelasId,
        studentName: account.namaPanggilan ?? account.nama,
      );
    }
  }

  /// Mengecek apakah ada perubahan jadwal untuk siswa tertentu
  Future<ScheduleChangeResult> _checkForChanges({
    required int siswaId,
    required int kelasId,
    required String studentName,
  }) async {
    try {
      // Ambil last seen dari SharedPreferences (per-kelas)
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_getLastSeenKey(kelasId));

      // Build URL
      String url = '$_baseUrl/check_schedule_changes.php?kelas_id=$kelasId';
      if (lastSeen != null) {
        url += '&last_seen=${Uri.encodeComponent(lastSeen)}';
      }

      debugPrint(
        'ScheduleChangeMonitor: Checking changes for $studentName (kelas $kelasId)',
      );

      // Request ke API
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        final hasChanges = data['has_changes'] == true;
        final latestUpdate = data['latest_update'] as String?;

        // Simpan latest_update sebagai last_seen untuk pengecekan berikutnya
        if (latestUpdate != null) {
          await prefs.setString(_getLastSeenKey(kelasId), latestUpdate);
        }

        // Jika ada perubahan, tampilkan notifikasi untuk siswa ini
        if (hasChanges) {
          debugPrint(
            'ScheduleChangeMonitor: 🔔 Changes detected for $studentName!',
          );
          await _notificationService.showScheduleChangeNotification(
            siswaId: siswaId,
            studentName: studentName,
          );
        } else {
          debugPrint('ScheduleChangeMonitor: No changes for $studentName');
        }

        return ScheduleChangeResult(
          success: true,
          message: responseData['message'] ?? 'Success',
          hasChanges: hasChanges,
          latestUpdate: latestUpdate,
        );
      } else {
        return ScheduleChangeResult(
          success: false,
          message: responseData['message'] ?? 'Gagal mengecek perubahan',
          hasChanges: false,
        );
      }
    } catch (e) {
      debugPrint(
        'ScheduleChangeMonitor: Error checking changes for $studentName - $e',
      );
      return ScheduleChangeResult(
        success: false,
        message: 'Tidak dapat terhubung ke server',
        hasChanges: false,
      );
    }
  }

  /// Cek apakah sedang monitoring
  bool get isMonitoring => _isMonitoring;

  /// Reset last seen untuk semua kelas (untuk testing)
  Future<void> resetLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('schedule_last_seen_update_')) {
        await prefs.remove(key);
      }
    }
    debugPrint('ScheduleChangeMonitor: Reset all last seen');
  }
}
