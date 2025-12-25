import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'notification_settings_model.dart';

/// Global navigator key untuk navigasi dari notification callback
// ignore: unused_element
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Service untuk mengelola notifikasi penjemputan
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification plugin instance
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Keys untuk SharedPreferences
  static const String _settingsKey = 'notification_settings';

  // Notification IDs
  static const int _pickupNotificationId = 1001;

  // Flag untuk cek apakah sudah diinisialisasi
  bool _isInitialized = false;

  // Current settings cache
  NotificationSettings? _cachedSettings;

  /// Inisialisasi notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize notifications
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('NotificationService: Initialized');

    // Load cached settings
    _cachedSettings = await loadSettings();
  }

  /// Handler ketika notifikasi di-tap saat app foreground
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      'NotificationService: Notification tapped - ${response.payload}',
    );
  }

  /// Request permission untuk menampilkan notifikasi
  Future<bool> requestPermission() async {
    // Android 13+ memerlukan permission request
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS permission request
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Menjadwalkan notifikasi penjemputan
  ///
  /// [pickupTime] - Waktu kepulangan (DateTime hari ini dengan jam pulang)
  /// [minutesBefore] - Berapa menit sebelum jam pulang notifikasi muncul
  /// [studentName] - Nama siswa yang akan dijemput
  Future<void> schedulePickupNotification({
    required DateTime pickupTime,
    required int minutesBefore,
    required String studentName,
  }) async {
    await initialize();

    // Hitung waktu notifikasi
    final notificationTime = pickupTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // Jika waktu notifikasi sudah lewat, jangan jadwalkan
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('NotificationService: Notification time already passed');
      return;
    }

    // Konversi ke TZDateTime
    final tzNotificationTime = tz.TZDateTime.from(notificationTime, tz.local);

    // Format waktu pulang untuk ditampilkan
    final formattedPickupTime =
        '${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}';

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'pickup_reminder_channel',
      'Pengingat Penjemputan',
      channelDescription: 'Notifikasi pengingat untuk menjemput anak',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Pengingat Penjemputan',
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Jadwalkan notifikasi
    try {
      await _notifications.zonedSchedule(
        _pickupNotificationId,
        'Waktunya $studentName pulang',
        'Sebentar lagi pukul $formattedPickupTime. Bersiaplah untuk menjemput.',
        tzNotificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null, // Tidak berulang, hanya sekali
        payload: 'pickup_reminder',
      );

      debugPrint(
        'NotificationService: Scheduled notification for $tzNotificationTime',
      );
    } catch (e) {
      debugPrint('NotificationService: Error scheduling notification - $e');
    }
  }

  /// Menjadwalkan notifikasi harian berdasarkan jadwal
  ///
  /// [pickupTimeString] - Waktu kepulangan dalam format "HH:mm"
  /// [minutesBefore] - Berapa menit sebelum jam pulang
  /// [studentName] - Nama siswa
  Future<void> scheduleDailyPickupNotification({
    required String pickupTimeString,
    required int minutesBefore,
    required String studentName,
  }) async {
    // Parse waktu pulang
    final parts = pickupTimeString.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]) ?? 14;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Buat DateTime untuk hari ini dengan jam pulang
    final now = DateTime.now();
    var pickupTime = DateTime(now.year, now.month, now.day, hour, minute);

    // Jika waktu sudah lewat, jadwalkan untuk besok
    if (pickupTime.isBefore(now)) {
      pickupTime = pickupTime.add(const Duration(days: 1));
    }

    await schedulePickupNotification(
      pickupTime: pickupTime,
      minutesBefore: minutesBefore,
      studentName: studentName,
    );
  }

  /// Membatalkan notifikasi penjemputan
  Future<void> cancelPickupNotification() async {
    await _notifications.cancel(_pickupNotificationId);
    debugPrint('NotificationService: Cancelled pickup notification');
  }

  /// Membatalkan semua notifikasi
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  // ==========================================
  // SETTINGS PERSISTENCE
  // ==========================================

  /// Menyimpan pengaturan notifikasi
  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    _cachedSettings = settings; // Update cache
    debugPrint('NotificationService: Settings saved');
  }

  /// Memuat pengaturan notifikasi
  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return NotificationSettings.fromJson(json);
      } catch (e) {
        debugPrint('NotificationService: Error loading settings - $e');
      }
    }

    return const NotificationSettings();
  }

  /// Menampilkan notifikasi perubahan jadwal
  Future<void> showScheduleChangeNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'schedule_change_channel',
      'Perubahan Jadwal',
      channelDescription: 'Notifikasi saat ada perubahan jadwal kepulangan',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Perubahan Jadwal',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1002, // ID unik untuk notifikasi perubahan jadwal
      '📅 Perubahan Jadwal Pulang',
      'Cek jadwal kepulangan Ananda sekarang!',
      notificationDetails,
      payload: 'schedule_change',
    );

    debugPrint('NotificationService: Schedule change notification shown');
  }

  /// Menampilkan notifikasi test (untuk debugging)
  Future<void> showTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel untuk testing notifikasi',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🔔 Test Notifikasi',
      'Notifikasi pengingat penjemputan berhasil dikonfigurasi!',
      notificationDetails,
    );
  }
}

/// Handler untuk background notification - harus top-level function
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  debugPrint(
    'NotificationService: Background notification tapped - ${response.payload}',
  );
}
