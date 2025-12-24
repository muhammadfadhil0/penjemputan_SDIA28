-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Dec 24, 2025 at 03:13 PM
-- Server version: 10.11.15-MariaDB-cll-lve
-- PHP Version: 8.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `soua3852_penjemputansdia28`
--

-- --------------------------------------------------------

--
-- Table structure for table `guru_piket`
--

CREATE TABLE `guru_piket` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `tanggal` date NOT NULL,
  `shift` varchar(20) DEFAULT NULL COMMENT 'Jika ada pembagian shift',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jadwal_kelas`
--

CREATE TABLE `jadwal_kelas` (
  `id` int(11) NOT NULL,
  `kelas_id` int(11) NOT NULL,
  `hari` enum('senin','selasa','rabu','kamis','jumat','sabtu') NOT NULL,
  `jam_masuk` time NOT NULL,
  `jam_pulang` time NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `jadwal_kelas`
--

INSERT INTO `jadwal_kelas` (`id`, `kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `created_at`, `updated_at`) VALUES
(1, 5, 'senin', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(2, 5, 'selasa', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(3, 5, 'rabu', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(4, 5, 'kamis', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(5, 5, 'jumat', '07:00:00', '11:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20');

-- --------------------------------------------------------

--
-- Table structure for table `kelas`
--

CREATE TABLE `kelas` (
  `id` int(11) NOT NULL,
  `nama_kelas` varchar(10) NOT NULL COMMENT 'Contoh: 1A, 2B, 3A',
  `tingkat` int(11) NOT NULL COMMENT 'Tingkat 1-6',
  `tahun_ajaran` varchar(20) NOT NULL COMMENT 'Contoh: 2024/2025',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kelas`
--

INSERT INTO `kelas` (`id`, `nama_kelas`, `tingkat`, `tahun_ajaran`, `created_at`) VALUES
(1, '1A', 1, '2024/2025', '2025-12-22 08:51:20'),
(2, '1B', 1, '2024/2025', '2025-12-22 08:51:20'),
(3, '2A', 2, '2024/2025', '2025-12-22 08:51:20'),
(4, '2B', 2, '2024/2025', '2025-12-22 08:51:20'),
(5, '3A', 3, '2024/2025', '2025-12-22 08:51:20'),
(6, '3B', 3, '2024/2025', '2025-12-22 08:51:20'),
(7, '4A', 4, '2024/2025', '2025-12-22 08:51:20'),
(8, '4B', 4, '2024/2025', '2025-12-22 08:51:20'),
(9, '5A', 5, '2024/2025', '2025-12-22 08:51:20'),
(10, '5B', 5, '2024/2025', '2025-12-22 08:51:20'),
(11, '6A', 6, '2024/2025', '2025-12-22 08:51:20'),
(12, '6B', 6, '2024/2025', '2025-12-22 08:51:20');

-- --------------------------------------------------------

--
-- Table structure for table `login_kelas`
--

CREATE TABLE `login_kelas` (
  `id` int(11) NOT NULL,
  `kelas_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL COMMENT 'Contoh: kelas3a',
  `password` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `login_kelas`
--

INSERT INTO `login_kelas` (`id`, `kelas_id`, `username`, `password`, `created_at`) VALUES
(1, 5, 'kelas3a', 'kelas3a2024', '2025-12-22 08:51:20'),
(2, 6, 'kelas3b', 'kelas3b2024', '2025-12-22 08:51:20');

-- --------------------------------------------------------

--
-- Table structure for table `orang_tua_siswa`
--

CREATE TABLE `orang_tua_siswa` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `siswa_id` int(11) NOT NULL,
  `hubungan` enum('ayah','ibu','wali') NOT NULL DEFAULT 'wali',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orang_tua_siswa`
--

INSERT INTO `orang_tua_siswa` (`id`, `user_id`, `siswa_id`, `hubungan`, `created_at`) VALUES
(1, 3, 1, 'ayah', '2025-12-22 08:51:20'),
(2, 4, 1, 'ibu', '2025-12-22 08:51:20');

-- --------------------------------------------------------

--
-- Table structure for table `permintaan_jemput`
--

CREATE TABLE `permintaan_jemput` (
  `id` int(11) NOT NULL,
  `siswa_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL COMMENT 'Orang tua yang request',
  `penjemput` varchar(50) NOT NULL COMMENT 'ayah, ibu, ojek, lainnya',
  `penjemput_detail` varchar(100) DEFAULT NULL COMMENT 'Nama ojek/orang lain jika ada',
  `estimasi_waktu` enum('tiba','akan_tiba') NOT NULL DEFAULT 'tiba',
  `waktu_estimasi` time DEFAULT NULL COMMENT 'Jika akan_tiba, simpan jam estimasi',
  `status` enum('menunggu','dipanggil','dijemput','dibatalkan') NOT NULL DEFAULT 'menunggu',
  `nomor_antrian` int(11) NOT NULL COMMENT 'Nomor antrian pada hari itu',
  `waktu_request` timestamp NULL DEFAULT current_timestamp(),
  `waktu_dipanggil` timestamp NULL DEFAULT NULL,
  `waktu_dijemput` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `siswa`
--

CREATE TABLE `siswa` (
  `id` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `nama_panggilan` varchar(50) DEFAULT NULL,
  `kelas_id` int(11) NOT NULL,
  `foto_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `siswa`
--

INSERT INTO `siswa` (`id`, `nama`, `nama_panggilan`, `kelas_id`, `foto_url`, `created_at`) VALUES
(1, 'Ahmad Farhan Pratama', 'Farhan', 5, NULL, '2025-12-22 08:51:20'),
(2, 'Aisyah Putri Ramadhani', 'Aisyah', 5, NULL, '2025-12-22 08:51:20'),
(3, 'Budi Santoso', 'Budi', 5, NULL, '2025-12-22 08:51:20'),
(4, 'Citra Dewi Lestari', 'Citra', 5, NULL, '2025-12-22 08:51:20'),
(5, 'Dimas Prasetya', 'Dimas', 5, NULL, '2025-12-22 08:51:20');

-- --------------------------------------------------------

--
-- Table structure for table `status_penjemputan_harian`
--

CREATE TABLE `status_penjemputan_harian` (
  `id` int(11) NOT NULL,
  `siswa_id` int(11) NOT NULL,
  `tanggal` date NOT NULL,
  `sudah_dijemput` tinyint(1) NOT NULL DEFAULT 0,
  `waktu_dijemput` timestamp NULL DEFAULT NULL,
  `penjemput` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(100) NOT NULL,
  `role` enum('parent','teacher','class_viewer') NOT NULL DEFAULT 'parent',
  `nama` varchar(100) NOT NULL,
  `no_telepon` varchar(20) DEFAULT NULL,
  `last_pickup_request` timestamp NULL DEFAULT NULL COMMENT 'Untuk fitur cooldown 10 menit',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`, `nama`, `no_telepon`, `last_pickup_request`, `created_at`, `updated_at`) VALUES
(1, 'siri.rofikah', 'guru123', 'teacher', 'Siri Rofikah S.Pd', '081234567890', NULL, '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(2, 'ahmad.fadil', 'guru123', 'teacher', 'Ahmad Fadil S.Pd', '081234567891', NULL, '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(3, 'bapak.farhan', 'ortu123', 'parent', 'Bapak Farhan', '081234567892', NULL, '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(4, 'ibu.farhan', 'ortu123', 'parent', 'Ibu Farhan', '081234567893', NULL, '2025-12-22 08:51:20', '2025-12-22 08:51:20');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_antrian_hari_ini`
-- (See below for the actual view)
--
CREATE TABLE `v_antrian_hari_ini` (
`id` int(11)
,`nomor_antrian` int(11)
,`nama_siswa` varchar(100)
,`nama_kelas` varchar(10)
,`penjemput` varchar(50)
,`penjemput_detail` varchar(100)
,`estimasi_waktu` enum('tiba','akan_tiba')
,`waktu_estimasi` time
,`status` enum('menunggu','dipanggil','dijemput','dibatalkan')
,`waktu_request` timestamp
,`waktu_dipanggil` timestamp
,`nama_ortu` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_status_kelas_hari_ini`
-- (See below for the actual view)
--
CREATE TABLE `v_status_kelas_hari_ini` (
`siswa_id` int(11)
,`nama_siswa` varchar(100)
,`kelas_id` int(11)
,`nama_kelas` varchar(10)
,`sudah_dijemput` int(4)
,`waktu_dijemput` timestamp
,`penjemput` varchar(50)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `guru_piket`
--
ALTER TABLE `guru_piket`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tanggal` (`tanggal`),
  ADD KEY `idx_user` (`user_id`);

--
-- Indexes for table `jadwal_kelas`
--
ALTER TABLE `jadwal_kelas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_jadwal` (`kelas_id`,`hari`),
  ADD KEY `idx_kelas` (`kelas_id`);

--
-- Indexes for table `kelas`
--
ALTER TABLE `kelas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_kelas_tahun` (`nama_kelas`,`tahun_ajaran`),
  ADD KEY `idx_tingkat` (`tingkat`);

--
-- Indexes for table `login_kelas`
--
ALTER TABLE `login_kelas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_kelas` (`kelas_id`);

--
-- Indexes for table `orang_tua_siswa`
--
ALTER TABLE `orang_tua_siswa`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_ortu_siswa` (`user_id`,`siswa_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_siswa` (`siswa_id`);

--
-- Indexes for table `permintaan_jemput`
--
ALTER TABLE `permintaan_jemput`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_siswa` (`siswa_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_tanggal` (`waktu_request`);

--
-- Indexes for table `siswa`
--
ALTER TABLE `siswa`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_kelas` (`kelas_id`),
  ADD KEY `idx_nama` (`nama`);

--
-- Indexes for table `status_penjemputan_harian`
--
ALTER TABLE `status_penjemputan_harian`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_siswa_tanggal` (`siswa_id`,`tanggal`),
  ADD KEY `idx_tanggal` (`tanggal`),
  ADD KEY `idx_status` (`sudah_dijemput`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_role` (`role`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `guru_piket`
--
ALTER TABLE `guru_piket`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jadwal_kelas`
--
ALTER TABLE `jadwal_kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `kelas`
--
ALTER TABLE `kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `login_kelas`
--
ALTER TABLE `login_kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `orang_tua_siswa`
--
ALTER TABLE `orang_tua_siswa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `permintaan_jemput`
--
ALTER TABLE `permintaan_jemput`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `siswa`
--
ALTER TABLE `siswa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `status_penjemputan_harian`
--
ALTER TABLE `status_penjemputan_harian`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

-- --------------------------------------------------------

--
-- Structure for view `v_antrian_hari_ini`
--
DROP TABLE IF EXISTS `v_antrian_hari_ini`;

CREATE ALGORITHM=UNDEFINED DEFINER=`soua3852`@`localhost` SQL SECURITY DEFINER VIEW `v_antrian_hari_ini`  AS SELECT `pj`.`id` AS `id`, `pj`.`nomor_antrian` AS `nomor_antrian`, `s`.`nama` AS `nama_siswa`, `k`.`nama_kelas` AS `nama_kelas`, `pj`.`penjemput` AS `penjemput`, `pj`.`penjemput_detail` AS `penjemput_detail`, `pj`.`estimasi_waktu` AS `estimasi_waktu`, `pj`.`waktu_estimasi` AS `waktu_estimasi`, `pj`.`status` AS `status`, `pj`.`waktu_request` AS `waktu_request`, `pj`.`waktu_dipanggil` AS `waktu_dipanggil`, `u`.`nama` AS `nama_ortu` FROM (((`permintaan_jemput` `pj` join `siswa` `s` on(`pj`.`siswa_id` = `s`.`id`)) join `kelas` `k` on(`s`.`kelas_id` = `k`.`id`)) join `users` `u` on(`pj`.`user_id` = `u`.`id`)) WHERE cast(`pj`.`waktu_request` as date) = curdate() ORDER BY `pj`.`nomor_antrian` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_status_kelas_hari_ini`
--
DROP TABLE IF EXISTS `v_status_kelas_hari_ini`;

CREATE ALGORITHM=UNDEFINED DEFINER=`soua3852`@`localhost` SQL SECURITY DEFINER VIEW `v_status_kelas_hari_ini`  AS SELECT `s`.`id` AS `siswa_id`, `s`.`nama` AS `nama_siswa`, `k`.`id` AS `kelas_id`, `k`.`nama_kelas` AS `nama_kelas`, coalesce(`sph`.`sudah_dijemput`,0) AS `sudah_dijemput`, `sph`.`waktu_dijemput` AS `waktu_dijemput`, `sph`.`penjemput` AS `penjemput` FROM ((`siswa` `s` join `kelas` `k` on(`s`.`kelas_id` = `k`.`id`)) left join `status_penjemputan_harian` `sph` on(`s`.`id` = `sph`.`siswa_id` and `sph`.`tanggal` = curdate())) ORDER BY `k`.`nama_kelas` ASC, `s`.`nama` ASC ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `guru_piket`
--
ALTER TABLE `guru_piket`
  ADD CONSTRAINT `guru_piket_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `jadwal_kelas`
--
ALTER TABLE `jadwal_kelas`
  ADD CONSTRAINT `jadwal_kelas_ibfk_1` FOREIGN KEY (`kelas_id`) REFERENCES `kelas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `login_kelas`
--
ALTER TABLE `login_kelas`
  ADD CONSTRAINT `login_kelas_ibfk_1` FOREIGN KEY (`kelas_id`) REFERENCES `kelas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `orang_tua_siswa`
--
ALTER TABLE `orang_tua_siswa`
  ADD CONSTRAINT `orang_tua_siswa_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `orang_tua_siswa_ibfk_2` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `permintaan_jemput`
--
ALTER TABLE `permintaan_jemput`
  ADD CONSTRAINT `permintaan_jemput_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `permintaan_jemput_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `siswa`
--
ALTER TABLE `siswa`
  ADD CONSTRAINT `siswa_ibfk_1` FOREIGN KEY (`kelas_id`) REFERENCES `kelas` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `status_penjemputan_harian`
--
ALTER TABLE `status_penjemputan_harian`
  ADD CONSTRAINT `status_penjemputan_harian_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
