import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/notification_service.dart';
import '../auth/auth_service.dart';

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
class ScheduleChangeMonitor {
  // Singleton instance
  static final ScheduleChangeMonitor _instance =
      ScheduleChangeMonitor._internal();
  factory ScheduleChangeMonitor() => _instance;
  ScheduleChangeMonitor._internal();

  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/jadwal';

  // Key untuk SharedPreferences
  static const String _lastSeenKey = 'schedule_last_seen_update';

  // Interval polling (5 menit)
  static const Duration _pollInterval = Duration(minutes: 10);

  // Timer untuk polling
  Timer? _pollTimer;

  // Flag apakah monitoring aktif
  bool _isMonitoring = false;

  // Dependencies
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

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

    // Lakukan pengecekan pertama
    await _checkForChanges();

    // Set up polling timer
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _checkForChanges();
    });
  }

  /// Menghentikan monitoring
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isMonitoring = false;
    debugPrint('ScheduleChangeMonitor: Stopped monitoring');
  }

  /// Mengecek apakah ada perubahan jadwal
  Future<ScheduleChangeResult> _checkForChanges() async {
    try {
      // Ambil data user yang login
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('ScheduleChangeMonitor: No user logged in');
        return ScheduleChangeResult(
          success: false,
          message: 'User tidak login',
          hasChanges: false,
        );
      }

      final kelasId = currentUser.kelasId;

      // Ambil last seen dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_lastSeenKey);

      // Build URL
      String url = '$_baseUrl/check_schedule_changes.php?kelas_id=$kelasId';
      if (lastSeen != null) {
        url += '&last_seen=${Uri.encodeComponent(lastSeen)}';
      }

      debugPrint('ScheduleChangeMonitor: Checking changes for kelas $kelasId');
      debugPrint('ScheduleChangeMonitor: Last seen = $lastSeen');

      // Request ke API
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      debugPrint('ScheduleChangeMonitor: API Response = ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        final hasChanges = data['has_changes'] == true;
        final latestUpdate = data['latest_update'] as String?;

        debugPrint('ScheduleChangeMonitor: Latest update = $latestUpdate');
        debugPrint('ScheduleChangeMonitor: Has changes = $hasChanges');

        // Simpan latest_update sebagai last_seen untuk pengecekan berikutnya
        if (latestUpdate != null) {
          await prefs.setString(_lastSeenKey, latestUpdate);
        }

        // Jika ada perubahan, tampilkan notifikasi
        if (hasChanges) {
          debugPrint(
            'ScheduleChangeMonitor: 🔔 Changes detected! Showing notification...',
          );
          await _notificationService.showScheduleChangeNotification();
        } else {
          debugPrint('ScheduleChangeMonitor: No changes');
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
      debugPrint('ScheduleChangeMonitor: Error checking changes - $e');
      return ScheduleChangeResult(
        success: false,
        message: 'Tidak dapat terhubung ke server',
        hasChanges: false,
      );
    }
  }

  /// Cek apakah sedang monitoring
  bool get isMonitoring => _isMonitoring;

  /// Reset last seen (untuk testing)
  Future<void> resetLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
    debugPrint('ScheduleChangeMonitor: Reset last seen');
  }
}
