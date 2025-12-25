/// Mode pengingat: notifikasi biasa atau layar penuh (alarm)
enum AlertMode {
  notification, // Notifikasi standar
  fullscreen, // Layar penuh seperti alarm
}

/// Model untuk menyimpan pengaturan notifikasi
class NotificationSettings {
  final bool pickupReminderEnabled;
  final int minutesBeforePickup;
  final bool scheduleChangeEnabled;
  final AlertMode alertMode;
  final String notificationSound; // Nama file di assets/sounds/notification/
  final String alarmSound; // Nama file di assets/sounds/ringtone/

  const NotificationSettings({
    this.pickupReminderEnabled = false,
    this.minutesBeforePickup = 15,
    this.scheduleChangeEnabled = false,
    this.alertMode = AlertMode.notification,
    this.notificationSound = 'Bell',
    this.alarmSound = 'Kami Al Azhar',
  });

  /// Membuat NotificationSettings dari JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pickupReminderEnabled: json['pickup_reminder_enabled'] ?? false,
      minutesBeforePickup: json['minutes_before_pickup'] ?? 15,
      scheduleChangeEnabled: json['schedule_change_enabled'] ?? false,
      alertMode: AlertMode.values.firstWhere(
        (e) => e.name == json['alert_mode'],
        orElse: () => AlertMode.notification,
      ),
      notificationSound: json['notification_sound'] ?? 'default',
      alarmSound: json['alarm_sound'] ?? 'ringtone',
    );
  }

  /// Konversi ke JSON untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'pickup_reminder_enabled': pickupReminderEnabled,
      'minutes_before_pickup': minutesBeforePickup,
      'schedule_change_enabled': scheduleChangeEnabled,
      'alert_mode': alertMode.name,
      'notification_sound': notificationSound,
      'alarm_sound': alarmSound,
    };
  }

  /// Copy with untuk update settings
  NotificationSettings copyWith({
    bool? pickupReminderEnabled,
    int? minutesBeforePickup,
    bool? scheduleChangeEnabled,
    AlertMode? alertMode,
    String? notificationSound,
    String? alarmSound,
  }) {
    return NotificationSettings(
      pickupReminderEnabled:
          pickupReminderEnabled ?? this.pickupReminderEnabled,
      minutesBeforePickup: minutesBeforePickup ?? this.minutesBeforePickup,
      scheduleChangeEnabled:
          scheduleChangeEnabled ?? this.scheduleChangeEnabled,
      alertMode: alertMode ?? this.alertMode,
      notificationSound: notificationSound ?? this.notificationSound,
      alarmSound: alarmSound ?? this.alarmSound,
    );
  }

  /// Helper untuk mendapatkan label mode
  String get alertModeLabel =>
      alertMode == AlertMode.notification ? 'Notifikasi' : 'Layar Penuh';
}
