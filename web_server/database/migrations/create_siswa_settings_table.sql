-- Tabel untuk menyimpan settings per-siswa
-- Digunakan untuk sync settings antar device

CREATE TABLE `siswa_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `siswa_id` int(11) NOT NULL,
  `pickup_reminder_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `minutes_before_pickup` int(11) NOT NULL DEFAULT 15,
  `schedule_change_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `notification_sound` varchar(50) DEFAULT 'Bell',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_siswa` (`siswa_id`),
  CONSTRAINT `siswa_settings_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
