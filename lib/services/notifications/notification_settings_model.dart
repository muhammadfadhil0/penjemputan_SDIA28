/// Model untuk menyimpan pengaturan notifikasi
class NotificationSettings {
  final bool pickupReminderEnabled;
  final int minutesBeforePickup;
  final bool scheduleChangeEnabled;

  const NotificationSettings({
    this.pickupReminderEnabled = false,
    this.minutesBeforePickup = 15,
    this.scheduleChangeEnabled = false,
  });

  /// Membuat NotificationSettings dari JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pickupReminderEnabled: json['pickup_reminder_enabled'] ?? false,
      minutesBeforePickup: json['minutes_before_pickup'] ?? 15,
      scheduleChangeEnabled: json['schedule_change_enabled'] ?? false,
    );
  }

  /// Konversi ke JSON untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'pickup_reminder_enabled': pickupReminderEnabled,
      'minutes_before_pickup': minutesBeforePickup,
      'schedule_change_enabled': scheduleChangeEnabled,
    };
  }

  /// Copy with untuk update settings
  NotificationSettings copyWith({
    bool? pickupReminderEnabled,
    int? minutesBeforePickup,
    bool? scheduleChangeEnabled,
  }) {
    return NotificationSettings(
      pickupReminderEnabled:
          pickupReminderEnabled ?? this.pickupReminderEnabled,
      minutesBeforePickup: minutesBeforePickup ?? this.minutesBeforePickup,
      scheduleChangeEnabled:
          scheduleChangeEnabled ?? this.scheduleChangeEnabled,
    );
  }
}
