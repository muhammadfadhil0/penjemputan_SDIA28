-- =====================================================
-- SQL Script: Update Kelas & Jadwal for SDIA 28
-- =====================================================
-- Menambahkan kelas baru (1C-D, 2C-D, 3C-D, 4C-D, 5C-D, 6C)
-- dan membuat jadwal default untuk semua kelas
-- =====================================================

-- Tambah kelas baru (11 kelas tambahan)
INSERT IGNORE INTO `kelas` (`id`, `nama_kelas`, `tingkat`, `tahun_ajaran`, `created_at`) VALUES
-- Kelas 1 tambahan
(13, '1C', 1, '2024/2025', NOW()),
(14, '1D', 1, '2024/2025', NOW()),
-- Kelas 2 tambahan
(15, '2C', 2, '2024/2025', NOW()),
(16, '2D', 2, '2024/2025', NOW()),
-- Kelas 3 tambahan
(17, '3C', 3, '2024/2025', NOW()),
(18, '3D', 3, '2024/2025', NOW()),
-- Kelas 4 tambahan
(19, '4C', 4, '2024/2025', NOW()),
(20, '4D', 4, '2024/2025', NOW()),
-- Kelas 5 tambahan
(21, '5C', 5, '2024/2025', NOW()),
(22, '5D', 5, '2024/2025', NOW()),
-- Kelas 6 tambahan (hanya C)
(23, '6C', 6, '2024/2025', NOW());

-- =====================================================
-- Buat jadwal default untuk SEMUA kelas yang belum ada
-- =====================================================

-- Prosedur untuk insert jadwal jika belum ada
-- Kelas Tingkat 1 (jam pulang 11:30)
INSERT IGNORE INTO `jadwal_kelas` (`kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `is_holiday`) 
SELECT k.id, h.hari, '07:00:00', '11:30:00', 0
FROM `kelas` k
CROSS JOIN (SELECT 'senin' as hari UNION SELECT 'selasa' UNION SELECT 'rabu' UNION SELECT 'kamis' UNION SELECT 'jumat') h
WHERE k.tingkat = 1
AND NOT EXISTS (SELECT 1 FROM `jadwal_kelas` jk WHERE jk.kelas_id = k.id AND jk.hari = h.hari);

-- Kelas Tingkat 2 (jam pulang 12:00)
INSERT IGNORE INTO `jadwal_kelas` (`kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `is_holiday`) 
SELECT k.id, h.hari, '07:00:00', '12:00:00', 0
FROM `kelas` k
CROSS JOIN (SELECT 'senin' as hari UNION SELECT 'selasa' UNION SELECT 'rabu' UNION SELECT 'kamis' UNION SELECT 'jumat') h
WHERE k.tingkat = 2
AND NOT EXISTS (SELECT 1 FROM `jadwal_kelas` jk WHERE jk.kelas_id = k.id AND jk.hari = h.hari);

-- Kelas Tingkat 3 (jam pulang 12:30)
INSERT IGNORE INTO `jadwal_kelas` (`kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `is_holiday`) 
SELECT k.id, h.hari, '07:00:00', '12:30:00', 0
FROM `kelas` k
CROSS JOIN (SELECT 'senin' as hari UNION SELECT 'selasa' UNION SELECT 'rabu' UNION SELECT 'kamis' UNION SELECT 'jumat') h
WHERE k.tingkat = 3
AND NOT EXISTS (SELECT 1 FROM `jadwal_kelas` jk WHERE jk.kelas_id = k.id AND jk.hari = h.hari);

-- Kelas Tingkat 4 (jam pulang 13:00)
INSERT IGNORE INTO `jadwal_kelas` (`kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `is_holiday`) 
SELECT k.id, h.hari, '07:00:00', '13:00:00', 0
FROM `kelas` k
CROSS JOIN (SELECT 'senin' as hari UNION SELECT 'selasa' UNION SELECT 'rabu' UNION SELECT 'kamis' UNION SELECT 'jumat') h
WHERE k.tingkat = 4
AND NOT EXISTS (SELECT 1 FROM `jadwal_kelas` jk WHERE jk.kelas_id = k.id AND jk.hari = h.hari);

-- Kelas Tingkat 5 (jam pulang 13:30)
INSERT IGNORE INTO `jadwal_kelas` (`kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `is_holiday`) 
SELECT k.id, h.hari, '07:00:00', '13:30:00', 0
FROM `kelas` k
CROSS JOIN (SELECT 'senin' as hari UNION SELECT 'selasa' UNION SELECT 'rabu' UNION SELECT 'kamis' UNION SELECT 'jumat') h
WHERE k.tingkat = 5
AND NOT EXISTS (SELECT 1 FROM `jadwal_kelas` jk WHERE jk.kelas_id = k.id AND jk.hari = h.hari);

-- Kelas Tingkat 6 (jam pulang 14:00)
INSERT IGNORE INTO `jadwal_kelas` (`kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `is_holiday`) 
SELECT k.id, h.hari, '07:00:00', '14:00:00', 0
FROM `kelas` k
CROSS JOIN (SELECT 'senin' as hari UNION SELECT 'selasa' UNION SELECT 'rabu' UNION SELECT 'kamis' UNION SELECT 'jumat') h
WHERE k.tingkat = 6
AND NOT EXISTS (SELECT 1 FROM `jadwal_kelas` jk WHERE jk.kelas_id = k.id AND jk.hari = h.hari);

-- =====================================================
-- Verifikasi hasil
-- =====================================================
-- Jalankan query berikut untuk verifikasi:
-- SELECT * FROM kelas ORDER BY tingkat, nama_kelas;
-- SELECT COUNT(*) as total_jadwal FROM jadwal_kelas;
