-- =====================================================
-- ALTER TABLE: Menambahkan kolom is_holiday ke jadwal_kelas
-- SDIA 28 - Sistem Penjemputan Siswa
-- Jalankan query ini di phpMyAdmin atau MySQL client
-- =====================================================

-- Cek apakah kolom sudah ada, jika belum tambahkan
-- (Untuk MySQL/MariaDB)

ALTER TABLE `jadwal_kelas` 
ADD COLUMN `is_holiday` TINYINT(1) NOT NULL DEFAULT 0 
COMMENT 'Status libur: 0=aktif, 1=libur'
AFTER `jam_pulang`;

-- Query di atas akan:
-- 1. Menambahkan kolom is_holiday dengan tipe TINYINT(1) 
-- 2. Default value 0 (tidak libur)
-- 3. Posisi setelah kolom jam_pulang
