-- Migration: Add pengaturan_aplikasi table
-- Tabel untuk menyimpan konfigurasi aplikasi seperti cooldown, dll.

CREATE TABLE IF NOT EXISTS `pengaturan_aplikasi` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `key_name` varchar(50) NOT NULL,
    `value` varchar(255) NOT NULL,
    `description` varchar(255) DEFAULT NULL,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `key_name` (`key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default cooldown value (10 minutes)
INSERT INTO `pengaturan_aplikasi` (`key_name`, `value`, `description`) 
VALUES ('cooldown_minutes', '10', 'Durasi cooldown dalam menit sebelum bisa memanggil kembali')
ON DUPLICATE KEY UPDATE `key_name` = `key_name`;

-- Add column to store cooldown per-request (so countdown doesn't change when admin updates settings)
ALTER TABLE `permintaan_jemput` 
ADD COLUMN IF NOT EXISTS `cooldown_minutes_used` INT(11) DEFAULT 10 
COMMENT 'Nilai cooldown yang digunakan saat request ini dibuat';
