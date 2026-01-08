/// Model untuk settings notifikasi per-siswa
/// Mendukung sync dengan server dan local cache
class SiswaSettings {
  final bool pickupReminderEnabled;
  final int minutesBeforePickup;
  final bool scheduleChangeEnabled;
  final String notificationSound;
  final DateTime? updatedAt;

  const SiswaSettings({
    this.pickupReminderEnabled = false,
    this.minutesBeforePickup = 15,
    this.scheduleChangeEnabled = false,
    this.notificationSound = 'Bell',
    this.updatedAt,
  });

  /// Factory untuk membuat default settings
  factory SiswaSettings.defaults() => const SiswaSettings();

  /// Membuat SiswaSettings dari JSON (response API)
  factory SiswaSettings.fromJson(Map<String, dynamic> json) {
    return SiswaSettings(
      pickupReminderEnabled: json['pickup_reminder_enabled'] ?? false,
      minutesBeforePickup: json['minutes_before_pickup'] ?? 15,
      scheduleChangeEnabled: json['schedule_change_enabled'] ?? false,
      notificationSound: json['notification_sound'] ?? 'Bell',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Konversi ke JSON untuk API request dan local storage
  Map<String, dynamic> toJson() {
    return {
      'pickup_reminder_enabled': pickupReminderEnabled,
      'minutes_before_pickup': minutesBeforePickup,
      'schedule_change_enabled': scheduleChangeEnabled,
      'notification_sound': notificationSound,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with untuk update settings
  SiswaSettings copyWith({
    bool? pickupReminderEnabled,
    int? minutesBeforePickup,
    bool? scheduleChangeEnabled,
    String? notificationSound,
    DateTime? updatedAt,
  }) {
    return SiswaSettings(
      pickupReminderEnabled:
          pickupReminderEnabled ?? this.pickupReminderEnabled,
      minutesBeforePickup: minutesBeforePickup ?? this.minutesBeforePickup,
      scheduleChangeEnabled:
          scheduleChangeEnabled ?? this.scheduleChangeEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Cek apakah settings sama dengan settings lain
  bool isEqualTo(SiswaSettings other) {
    return pickupReminderEnabled == other.pickupReminderEnabled &&
        minutesBeforePickup == other.minutesBeforePickup &&
        scheduleChangeEnabled == other.scheduleChangeEnabled &&
        notificationSound == other.notificationSound;
  }

  @override
  String toString() {
    return 'SiswaSettings(pickup: $pickupReminderEnabled, minutes: $minutesBeforePickup, schedule: $scheduleChangeEnabled, sound: $notificationSound)';
  }
}
