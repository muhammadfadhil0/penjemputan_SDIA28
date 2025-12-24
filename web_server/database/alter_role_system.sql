-- ============================================
-- Migration SQL: Update Role System
-- SDIA 28 Sistem Penjemputan
-- ============================================
-- Jalankan script ini di phpMyAdmin untuk:
-- 1. Mengubah role dari parent/teacher menjadi guru/siswa
-- 2. Menambah field login ke tabel siswa
-- ============================================

-- Backup data users terlebih dahulu jika diperlukan
-- CREATE TABLE users_backup AS SELECT * FROM users;

-- ============================================
-- Step 1: Update existing data di tabel users
-- ============================================

-- Update role 'teacher' menjadi 'guru'
UPDATE `users` SET `role` = 'teacher' WHERE `role` = 'teacher';
-- Catatan: ini akan dihandle oleh ALTER di bawah

-- ============================================
-- Step 2: Alter tabel users untuk role baru
-- ============================================

-- Ubah enum role (harus update data dulu jika ada nilai lama)
-- Karena MariaDB, kita perlu approach berbeda

-- Pertama, tambah nilai enum baru
ALTER TABLE `users` 
MODIFY COLUMN `role` ENUM('parent','teacher','class_viewer','guru') NOT NULL DEFAULT 'guru';

-- Update data dari teacher ke guru
UPDATE `users` SET `role` = 'guru' WHERE `role` = 'teacher';

-- Sekarang hapus nilai lama dari enum
ALTER TABLE `users` 
MODIFY COLUMN `role` ENUM('guru','class_viewer') NOT NULL DEFAULT 'guru';

-- ============================================
-- Step 3: Tambah field login ke tabel siswa
-- ============================================

-- Tambah kolom username
ALTER TABLE `siswa` 
ADD COLUMN `username` VARCHAR(50) NULL AFTER `foto_url`;

-- Tambah kolom password
ALTER TABLE `siswa` 
ADD COLUMN `password` VARCHAR(100) NULL AFTER `username`;

-- Tambah kolom no_telepon_ortu untuk kontak orang tua
ALTER TABLE `siswa` 
ADD COLUMN `no_telepon_ortu` VARCHAR(20) NULL AFTER `password`;

-- Tambah kolom last_pickup_request untuk fitur cooldown
ALTER TABLE `siswa` 
ADD COLUMN `last_pickup_request` TIMESTAMP NULL DEFAULT NULL AFTER `no_telepon_ortu`;

-- Buat unique index untuk username siswa
ALTER TABLE `siswa` 
ADD UNIQUE INDEX `idx_siswa_username` (`username`);

-- ============================================
-- Step 4: Generate username & password untuk siswa yang sudah ada
-- ============================================

-- Untuk siswa yang sudah ada, generate username dari nama_panggilan atau nama
-- Format: siswa_[nama_panggilan lowercase tanpa spasi]

UPDATE `siswa` 
SET `username` = CONCAT('siswa_', LOWER(REPLACE(IFNULL(`nama_panggilan`, LEFT(`nama`, 10)), ' ', '_'))),
    `password` = 'siswa123'
WHERE `username` IS NULL;

-- ============================================
-- Step 5: Insert sample data guru (opsional)
-- ============================================

-- Update data guru yang sudah ada untuk memastikan role = 'guru'
-- Data sudah di-update di Step 2

-- ============================================
-- Step 6: Catatan tentang tabel orang_tua_siswa
-- ============================================

-- Tabel orang_tua_siswa di-keep untuk backward compatibility
-- Tidak dihapus karena mungkin diperlukan untuk referensi data histori
-- Jika ingin menghapus, uncomment baris di bawah:
-- DROP TABLE IF EXISTS `orang_tua_siswa`;

-- ============================================
-- Verifikasi hasil migrasi
-- ============================================

-- Cek struktur users
-- DESCRIBE `users`;

-- Cek struktur siswa
-- DESCRIBE `siswa`;

-- Cek data siswa dengan username
-- SELECT id, nama, nama_panggilan, username FROM `siswa`;
