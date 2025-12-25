-- Migration: Add guru_session_aktif table
-- File: web_server/database/migration_guru_session_aktif.sql
-- Description: Tabel untuk tracking guru yang sedang aktif login di web dashboard

CREATE TABLE IF NOT EXISTS `guru_session_aktif` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `login_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `last_heartbeat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`),
  CONSTRAINT `fk_guru_session` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
