-- =====================================================
-- DATABASE: SALAM SDIA 28 - Sistem Penjemputan Siswa
-- Dibuat: 22 Desember 2024
-- =====================================================

-- Buat database (opsional, uncomment jika perlu)
-- CREATE DATABASE IF NOT EXISTS salam_sdia28;
-- USE salam_sdia28;

-- =====================================================
-- 1. TABEL USERS (Orang Tua, Guru, Admin)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    role ENUM('parent', 'teacher', 'class_viewer') NOT NULL DEFAULT 'parent',
    nama VARCHAR(100) NOT NULL,
    no_telepon VARCHAR(20),
    last_pickup_request TIMESTAMP NULL COMMENT 'Untuk fitur cooldown 10 menit',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 2. TABEL KELAS
-- =====================================================
CREATE TABLE IF NOT EXISTS kelas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_kelas VARCHAR(10) NOT NULL COMMENT 'Contoh: 1A, 2B, 3A',
    tingkat INT NOT NULL COMMENT 'Tingkat 1-6',
    tahun_ajaran VARCHAR(20) NOT NULL COMMENT 'Contoh: 2024/2025',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_kelas_tahun (nama_kelas, tahun_ajaran),
    INDEX idx_tingkat (tingkat)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 3. TABEL SISWA
-- =====================================================
CREATE TABLE IF NOT EXISTS siswa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    kelas_id INT NOT NULL,
    foto_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (kelas_id) REFERENCES kelas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_kelas (kelas_id),
    INDEX idx_nama (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 4. TABEL ORANG TUA SISWA (Relasi Many-to-Many)
-- =====================================================
CREATE TABLE IF NOT EXISTS orang_tua_siswa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    siswa_id INT NOT NULL,
    hubungan ENUM('ayah', 'ibu', 'wali') NOT NULL DEFAULT 'wali',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (siswa_id) REFERENCES siswa(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_ortu_siswa (user_id, siswa_id),
    INDEX idx_user (user_id),
    INDEX idx_siswa (siswa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 5. TABEL JADWAL KELAS (Jadwal Masuk/Pulang)
-- =====================================================
CREATE TABLE IF NOT EXISTS jadwal_kelas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kelas_id INT NOT NULL,
    hari ENUM('senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu') NOT NULL,
    jam_masuk TIME NOT NULL,
    jam_pulang TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (kelas_id) REFERENCES kelas(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_jadwal (kelas_id, hari),
    INDEX idx_kelas (kelas_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 6. TABEL GURU PIKET
-- =====================================================
CREATE TABLE IF NOT EXISTS guru_piket (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tanggal DATE NOT NULL,
    shift VARCHAR(20) NULL COMMENT 'Jika ada pembagian shift',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_tanggal (tanggal),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 7. TABEL PERMINTAAN JEMPUT
-- =====================================================
CREATE TABLE IF NOT EXISTS permintaan_jemput (
    id INT AUTO_INCREMENT PRIMARY KEY,
    siswa_id INT NOT NULL,
    user_id INT NOT NULL COMMENT 'Orang tua yang request',
    penjemput VARCHAR(50) NOT NULL COMMENT 'ayah, ibu, ojek, lainnya',
    penjemput_detail VARCHAR(100) NULL COMMENT 'Nama ojek/orang lain jika ada',
    estimasi_waktu ENUM('tiba', 'akan_tiba') NOT NULL DEFAULT 'tiba',
    waktu_estimasi TIME NULL COMMENT 'Jika akan_tiba, simpan jam estimasi',
    status ENUM('menunggu', 'dipanggil', 'dijemput', 'dibatalkan') NOT NULL DEFAULT 'menunggu',
    nomor_antrian INT NOT NULL COMMENT 'Nomor antrian pada hari itu',
    waktu_request TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    waktu_dipanggil TIMESTAMP NULL,
    waktu_dijemput TIMESTAMP NULL,
    
    FOREIGN KEY (siswa_id) REFERENCES siswa(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_siswa (siswa_id),
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_tanggal (waktu_request)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 8. TABEL LOGIN KELAS (Untuk View Status di TV)
-- =====================================================
CREATE TABLE IF NOT EXISTS login_kelas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kelas_id INT NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT 'Contoh: kelas3a',
    password VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (kelas_id) REFERENCES kelas(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_kelas (kelas_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 9. TABEL STATUS PENJEMPUTAN HARIAN
-- =====================================================
CREATE TABLE IF NOT EXISTS status_penjemputan_harian (
    id INT AUTO_INCREMENT PRIMARY KEY,
    siswa_id INT NOT NULL,
    tanggal DATE NOT NULL,
    sudah_dijemput BOOLEAN NOT NULL DEFAULT FALSE,
    waktu_dijemput TIMESTAMP NULL,
    penjemput VARCHAR(50) NULL,
    
    FOREIGN KEY (siswa_id) REFERENCES siswa(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY unique_siswa_tanggal (siswa_id, tanggal),
    INDEX idx_tanggal (tanggal),
    INDEX idx_status (sudah_dijemput)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- DATA CONTOH (SAMPLE DATA)
-- =====================================================

-- Insert Kelas
INSERT INTO kelas (nama_kelas, tingkat, tahun_ajaran) VALUES
('1A', 1, '2024/2025'),
('1B', 1, '2024/2025'),
('2A', 2, '2024/2025'),
('2B', 2, '2024/2025'),
('3A', 3, '2024/2025'),
('3B', 3, '2024/2025'),
('4A', 4, '2024/2025'),
('4B', 4, '2024/2025'),
('5A', 5, '2024/2025'),
('5B', 5, '2024/2025'),
('6A', 6, '2024/2025'),
('6B', 6, '2024/2025');

-- Insert User Guru Piket
INSERT INTO users (username, password, role, nama, no_telepon) VALUES
('siri.rofikah', 'guru123', 'teacher', 'Siri Rofikah S.Pd', '081234567890'),
('ahmad.fadil', 'guru123', 'teacher', 'Ahmad Fadil S.Pd', '081234567891');

-- Insert User Orang Tua (Contoh)
INSERT INTO users (username, password, role, nama, no_telepon) VALUES
('bapak.farhan', 'ortu123', 'parent', 'Bapak Farhan', '081234567892'),
('ibu.farhan', 'ortu123', 'parent', 'Ibu Farhan', '081234567893');

-- Insert Siswa (Contoh untuk Kelas 3A)
INSERT INTO siswa (nama, kelas_id) VALUES
('Ahmad Farhan Pratama', 5),
('Aisyah Putri Ramadhani', 5),
('Budi Santoso', 5),
('Citra Dewi Lestari', 5),
('Dimas Prasetya', 5);

-- Insert Relasi Orang Tua - Siswa
INSERT INTO orang_tua_siswa (user_id, siswa_id, hubungan) VALUES
(3, 1, 'ayah'),
(4, 1, 'ibu');

-- Insert Jadwal Kelas 3A
INSERT INTO jadwal_kelas (kelas_id, hari, jam_masuk, jam_pulang) VALUES
(5, 'senin', '07:00:00', '14:30:00'),
(5, 'selasa', '07:00:00', '14:30:00'),
(5, 'rabu', '07:00:00', '14:30:00'),
(5, 'kamis', '07:00:00', '14:30:00'),
(5, 'jumat', '07:00:00', '11:30:00');

-- Insert Login Kelas untuk TV
INSERT INTO login_kelas (kelas_id, username, password) VALUES
(5, 'kelas3a', 'kelas3a2024'),
(6, 'kelas3b', 'kelas3b2024');

-- =====================================================
-- VIEW: Daftar Antrian Hari Ini
-- =====================================================
CREATE OR REPLACE VIEW v_antrian_hari_ini AS
SELECT 
    pj.id,
    pj.nomor_antrian,
    s.nama AS nama_siswa,
    k.nama_kelas,
    pj.penjemput,
    pj.penjemput_detail,
    pj.estimasi_waktu,
    pj.waktu_estimasi,
    pj.status,
    pj.waktu_request,
    pj.waktu_dipanggil,
    u.nama AS nama_ortu
FROM permintaan_jemput pj
JOIN siswa s ON pj.siswa_id = s.id
JOIN kelas k ON s.kelas_id = k.id
JOIN users u ON pj.user_id = u.id
WHERE DATE(pj.waktu_request) = CURDATE()
ORDER BY pj.nomor_antrian ASC;

-- =====================================================
-- VIEW: Status Penjemputan Per Kelas Hari Ini
-- =====================================================
CREATE OR REPLACE VIEW v_status_kelas_hari_ini AS
SELECT 
    s.id AS siswa_id,
    s.nama AS nama_siswa,
    k.id AS kelas_id,
    k.nama_kelas,
    COALESCE(sph.sudah_dijemput, FALSE) AS sudah_dijemput,
    sph.waktu_dijemput,
    sph.penjemput
FROM siswa s
JOIN kelas k ON s.kelas_id = k.id
LEFT JOIN status_penjemputan_harian sph 
    ON s.id = sph.siswa_id 
    AND sph.tanggal = CURDATE()
ORDER BY k.nama_kelas, s.nama;

-- =====================================================
-- SELESAI
-- =====================================================
