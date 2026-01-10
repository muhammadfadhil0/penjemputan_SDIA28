-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jan 11, 2026 at 03:01 AM
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
-- Table structure for table `guru_session_aktif`
--

CREATE TABLE `guru_session_aktif` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `login_time` timestamp NULL DEFAULT current_timestamp(),
  `last_heartbeat` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `guru_session_aktif`
--

INSERT INTO `guru_session_aktif` (`id`, `user_id`, `login_time`, `last_heartbeat`) VALUES
(165, 4, '2026-01-10 19:05:22', '2026-01-10 19:05:22');

-- --------------------------------------------------------

--
-- Table structure for table `jadwal_kelas`
--

CREATE TABLE `jadwal_kelas` (
  `id` int(11) NOT NULL,
  `kelas_id` int(11) NOT NULL,
  `hari` enum('senin','selasa','rabu','kamis','jumat','sabtu','minggu') NOT NULL,
  `jam_masuk` time NOT NULL,
  `jam_pulang` time NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_holiday` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Status libur: 0=aktif, 1=libur'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `jadwal_kelas`
--

INSERT INTO `jadwal_kelas` (`id`, `kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `created_at`, `updated_at`, `is_holiday`) VALUES
(1, 1, 'senin', '07:00:00', '10:00:00', '2025-12-28 17:21:38', '2026-01-02 06:31:54', 0),
(2, 1, 'selasa', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2026-01-10 18:51:26', 0),
(3, 1, 'rabu', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(4, 1, 'kamis', '07:00:00', '17:44:00', '2025-12-28 17:21:38', '2026-01-08 10:36:45', 0),
(5, 1, 'jumat', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2026-01-08 10:49:20', 0),
(6, 2, 'senin', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(7, 2, 'selasa', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(8, 2, 'rabu', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(9, 2, 'kamis', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(10, 2, 'jumat', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(11, 3, 'senin', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(12, 3, 'selasa', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(13, 3, 'rabu', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(14, 3, 'kamis', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(15, 3, 'jumat', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(16, 4, 'senin', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(17, 4, 'selasa', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(18, 4, 'rabu', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(19, 4, 'kamis', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(20, 4, 'jumat', '07:00:00', '11:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(21, 5, 'senin', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(22, 5, 'selasa', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(23, 5, 'rabu', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2026-01-08 10:44:31', 0),
(24, 5, 'kamis', '07:00:00', '17:45:00', '2025-12-28 17:21:38', '2026-01-08 10:36:57', 0),
(25, 5, 'jumat', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2026-01-08 10:44:15', 0),
(26, 6, 'senin', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(27, 6, 'selasa', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(28, 6, 'rabu', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(29, 6, 'kamis', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(30, 6, 'jumat', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(31, 7, 'senin', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(32, 7, 'selasa', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(33, 7, 'rabu', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(34, 7, 'kamis', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(35, 7, 'jumat', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(36, 8, 'senin', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(37, 8, 'selasa', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(38, 8, 'rabu', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(39, 8, 'kamis', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(40, 8, 'jumat', '07:00:00', '12:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(41, 9, 'senin', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(42, 9, 'selasa', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(43, 9, 'rabu', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(44, 9, 'kamis', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(45, 9, 'jumat', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(46, 10, 'senin', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(47, 10, 'selasa', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(48, 10, 'rabu', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(49, 10, 'kamis', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(50, 10, 'jumat', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(51, 11, 'senin', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(52, 11, 'selasa', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(53, 11, 'rabu', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(54, 11, 'kamis', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(55, 11, 'jumat', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(56, 12, 'senin', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(57, 12, 'selasa', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(58, 12, 'rabu', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(59, 12, 'kamis', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(60, 12, 'jumat', '07:00:00', '12:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(61, 13, 'senin', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(62, 13, 'selasa', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(63, 13, 'rabu', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(64, 13, 'kamis', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(65, 13, 'jumat', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(66, 14, 'senin', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(67, 14, 'selasa', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(68, 14, 'rabu', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(69, 14, 'kamis', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(70, 14, 'jumat', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(71, 15, 'senin', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(72, 15, 'selasa', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(73, 15, 'rabu', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(74, 15, 'kamis', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(75, 15, 'jumat', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(76, 16, 'senin', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(77, 16, 'selasa', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(78, 16, 'rabu', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(79, 16, 'kamis', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(80, 16, 'jumat', '07:00:00', '13:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(81, 17, 'senin', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(82, 17, 'selasa', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(83, 17, 'rabu', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(84, 17, 'kamis', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(85, 17, 'jumat', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(86, 18, 'senin', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(87, 18, 'selasa', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(88, 18, 'rabu', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(89, 18, 'kamis', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(90, 18, 'jumat', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(91, 19, 'senin', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(92, 19, 'selasa', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(93, 19, 'rabu', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(94, 19, 'kamis', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(95, 19, 'jumat', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(96, 20, 'senin', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(97, 20, 'selasa', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(98, 20, 'rabu', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(99, 20, 'kamis', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(100, 20, 'jumat', '07:00:00', '13:30:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(101, 21, 'senin', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(102, 21, 'selasa', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(103, 21, 'rabu', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(104, 21, 'kamis', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(105, 21, 'jumat', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(106, 22, 'senin', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(107, 22, 'selasa', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(108, 22, 'rabu', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(109, 22, 'kamis', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(110, 22, 'jumat', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(111, 23, 'senin', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(112, 23, 'selasa', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(113, 23, 'rabu', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(114, 23, 'kamis', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(115, 23, 'jumat', '07:00:00', '14:00:00', '2025-12-28 17:21:38', '2025-12-28 17:21:38', 0),
(116, 1, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:30:01', 1),
(117, 2, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(118, 3, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(119, 4, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(120, 5, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(121, 6, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(122, 7, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(123, 8, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(124, 9, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(125, 10, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(126, 11, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(127, 12, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(128, 13, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(129, 14, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(130, 15, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(131, 16, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(132, 17, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(133, 18, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(134, 19, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(135, 20, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(136, 21, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(137, 22, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(138, 23, 'sabtu', '07:00:00', '07:00:00', '2025-12-28 20:24:22', '2025-12-28 20:24:22', 1),
(139, 1, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:30:04', 1),
(140, 2, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(141, 3, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(142, 4, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(143, 5, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(144, 6, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(145, 7, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(146, 8, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(147, 9, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(148, 10, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(149, 11, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(150, 12, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(151, 13, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(152, 14, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(153, 15, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(154, 16, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(155, 17, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(156, 18, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(157, 19, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(158, 20, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(159, 21, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(160, 22, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1),
(161, 23, 'minggu', '07:00:00', '07:00:00', '2025-12-28 20:24:35', '2025-12-28 20:24:35', 1);

-- --------------------------------------------------------

--
-- Table structure for table `kelas`
--

CREATE TABLE `kelas` (
  `id` int(11) NOT NULL,
  `nama_kelas` varchar(100) NOT NULL COMMENT 'Contoh: 1A, 2B, 3A',
  `tingkat` int(11) NOT NULL COMMENT 'Tingkat 1-6',
  `tahun_ajaran` varchar(20) NOT NULL COMMENT 'Contoh: 2024/2025',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kelas`
--

INSERT INTO `kelas` (`id`, `nama_kelas`, `tingkat`, `tahun_ajaran`, `created_at`) VALUES
(1, '1 Abu Bakar', 1, '2025/2026', '2025-12-28 17:21:38'),
(2, '1 Umar', 1, '2025/2026', '2025-12-28 17:21:38'),
(3, '1 Utsman', 1, '2025/2026', '2025-12-28 17:21:38'),
(4, '1 Ali', 1, '2025/2026', '2025-12-28 17:21:38'),
(5, '2 Abu Bakar', 2, '2025/2026', '2025-12-28 17:21:38'),
(6, '2 Umar', 2, '2025/2026', '2025-12-28 17:21:38'),
(7, '2 Utsman', 2, '2025/2026', '2025-12-28 17:21:38'),
(8, '2 Ali', 2, '2025/2026', '2025-12-28 17:21:38'),
(9, '3 Abu Bakar', 3, '2025/2026', '2025-12-28 17:21:38'),
(10, '3 Umar', 3, '2025/2026', '2025-12-28 17:21:38'),
(11, '3 Utsman', 3, '2025/2026', '2025-12-28 17:21:38'),
(12, '3 Ali', 3, '2025/2026', '2025-12-28 17:21:38'),
(13, '4 Abu Bakar', 4, '2025/2026', '2025-12-28 17:21:38'),
(14, '4 Umar', 4, '2025/2026', '2025-12-28 17:21:38'),
(15, '4 Utsman', 4, '2025/2026', '2025-12-28 17:21:38'),
(16, '4 Ali', 4, '2025/2026', '2025-12-28 17:21:38'),
(17, '5 Abu Bakar', 5, '2025/2026', '2025-12-28 17:21:38'),
(18, '5 Umar', 5, '2025/2026', '2025-12-28 17:21:38'),
(19, '5 Utsman', 5, '2025/2026', '2025-12-28 17:21:38'),
(20, '5 Ali', 5, '2025/2026', '2025-12-28 17:21:38'),
(21, '6 Abu Bakar', 6, '2025/2026', '2025-12-28 17:21:38'),
(22, '6 Umar', 6, '2025/2026', '2025-12-28 17:21:38'),
(23, '6 Utsman', 6, '2025/2026', '2025-12-28 17:21:38');

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
(1, 1, 'kelas1abubakar', 'kelas123', '2025-12-28 17:41:10'),
(2, 5, 'kelas2abubakar', 'kelas123', '2025-12-28 17:41:10'),
(3, 3, 'kelas1utsman', 'kelas123', '2026-01-02 03:13:42'),
(4, 4, 'kelas1ali', 'kelas123', '2026-01-02 03:13:42'),
(6, 6, 'kelas2umar', 'kelas123', '2026-01-02 03:13:42'),
(7, 7, 'kelas2utsman', 'kelas123', '2026-01-02 03:13:42'),
(8, 8, 'kelas2ali', 'kelas123', '2026-01-02 03:13:42'),
(9, 9, 'kelas3abubakar', 'kelas123', '2026-01-02 03:13:42'),
(10, 10, 'kelas3umar', 'kelas123', '2026-01-02 03:13:42'),
(11, 11, 'kelas3utsman', 'kelas123', '2026-01-02 03:13:42'),
(12, 12, 'kelas3ali', 'kelas123', '2026-01-02 03:13:42'),
(13, 13, 'kelas4abubakar', 'kelas123', '2026-01-02 03:13:42'),
(14, 14, 'kelas4umar', 'kelas123', '2026-01-02 03:13:42'),
(15, 15, 'kelas4utsman', 'kelas123', '2026-01-02 03:13:42'),
(16, 16, 'kelas4ali', 'kelas123', '2026-01-02 03:13:42'),
(17, 17, 'kelas5abubakar', 'kelas123', '2026-01-02 03:13:42'),
(18, 18, 'kelas5umar', 'kelas123', '2026-01-02 03:13:42'),
(19, 19, 'kelas5utsman', 'kelas123', '2026-01-02 03:13:42'),
(20, 20, 'kelas5ali', 'kelas123', '2026-01-02 03:13:42'),
(21, 21, 'kelas6abubakar', 'kelas123', '2026-01-02 03:13:42'),
(22, 22, 'kelas6umar', 'kelas123', '2026-01-02 03:13:42'),
(23, 23, 'kelas6utsman', 'kelas123', '2026-01-02 03:13:42');

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

-- --------------------------------------------------------

--
-- Table structure for table `pengaturan_aplikasi`
--

CREATE TABLE `pengaturan_aplikasi` (
  `id` int(11) NOT NULL,
  `key_name` varchar(50) NOT NULL,
  `value` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pengaturan_aplikasi`
--

INSERT INTO `pengaturan_aplikasi` (`id`, `key_name`, `value`, `description`, `updated_at`) VALUES
(1, 'cooldown_minutes', '1', 'Durasi cooldown dalam menit sebelum bisa memanggil kembali', '2026-01-10 18:47:26'),
(2, 'campus_latitude', '-7.55254290497381', 'Latitude lokasi penjemputan', '2026-01-10 18:47:26'),
(3, 'campus_longitude', '110.76492869379514', 'Longitude lokasi penjemputan', '2026-01-10 18:47:26'),
(4, 'campus_radius', '100', 'Radius lokasi penjemputan dalam meter', '2026-01-10 18:47:26'),
(5, 'campus_name', 'Lokasi', 'Nama lokasi penjemputan', '2026-01-10 18:47:26'),
(6, 'call_authority', 'index', 'Penentu perangkat yang menjalankan pemanggilan otomatis', '2026-01-10 18:47:25'),
(7, 'emergency_mode', '{\"active\":false,\"activated_by\":\"Muhammad Fadhil Manfa\",\"activated_by_id\":4,\"activated_by_role\":\"guru\",\"kelas_id\":null,\"kelas_name\":null,\"activated_at\":\"2026-01-10 01:42:57\",\"deactivated_at\":\"2026-01-10 01:43:19\",\"updated_at\":\"2026-01-10 01:42:57\"}', 'Status emergency mode (non-aktif)', '2026-01-09 18:43:19');

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
  `waktu_dijemput` timestamp NULL DEFAULT NULL,
  `cooldown_minutes_used` int(11) DEFAULT 10
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `permintaan_jemput`
--

INSERT INTO `permintaan_jemput` (`id`, `siswa_id`, `user_id`, `penjemput`, `penjemput_detail`, `estimasi_waktu`, `waktu_estimasi`, `status`, `nomor_antrian`, `waktu_request`, `waktu_dipanggil`, `waktu_dijemput`, `cooldown_minutes_used`) VALUES
(1, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 1, '2026-01-02 02:39:54', '2026-01-02 02:40:21', NULL, 20),
(2, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dijemput', 2, '2026-01-02 02:49:14', '2026-01-02 02:49:24', '2026-01-02 06:28:29', 1),
(3, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 3, '2026-01-02 03:19:04', '2026-01-02 03:19:22', NULL, 1),
(4, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 4, '2026-01-02 04:20:36', '2026-01-02 04:20:52', NULL, 1),
(5, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 5, '2026-01-02 04:24:14', '2026-01-02 04:24:23', '2026-01-02 04:26:54', 1),
(6, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 6, '2026-01-02 04:26:54', '2026-01-02 04:27:03', '2026-01-02 04:49:30', 1),
(7, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 7, '2026-01-02 04:49:30', '2026-01-02 04:49:59', '2026-01-02 05:15:53', 1),
(8, 1, 1, 'ibu', NULL, 'tiba', NULL, 'dijemput', 8, '2026-01-02 05:15:53', '2026-01-02 05:16:05', '2026-01-02 05:17:07', 1),
(9, 1, 1, 'kakek', NULL, 'tiba', NULL, 'dijemput', 9, '2026-01-02 05:17:07', '2026-01-02 05:17:12', '2026-01-02 06:26:09', 1),
(10, 1, 1, 'lainnya', 'kakek', 'tiba', NULL, 'dijemput', 10, '2026-01-02 06:26:09', '2026-01-02 06:26:22', '2026-01-02 12:17:47', 1),
(11, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dijemput', 11, '2026-01-02 06:28:29', '2026-01-02 06:28:37', '2026-01-02 07:56:32', 1),
(12, 2, 2, 'ayah', NULL, 'tiba', NULL, 'menunggu', 12, '2026-01-02 07:56:32', NULL, NULL, 1),
(13, 1, 1, 'ayah', NULL, 'tiba', NULL, 'menunggu', 13, '2026-01-02 12:17:47', NULL, NULL, 1),
(14, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 1, '2026-01-06 10:30:19', '2026-01-06 10:31:02', NULL, 1),
(15, 1, 1, 'guru', 'Muhammad Fadhil Manfa', 'tiba', NULL, 'dibatalkan', 2, '2026-01-06 11:30:03', NULL, NULL, 1),
(16, 1, 1, 'ayah', 'Muhammad Fadhil Manfa', 'tiba', NULL, 'dibatalkan', 3, '2026-01-06 11:36:23', NULL, NULL, 1),
(17, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 4, '2026-01-06 11:40:56', '2026-01-06 11:41:32', NULL, 1),
(18, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 5, '2026-01-06 12:03:28', '2026-01-06 12:04:11', NULL, 1),
(19, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 6, '2026-01-06 12:03:52', '2026-01-06 12:06:15', NULL, 1),
(22, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 7, '2026-01-06 12:09:11', '2026-01-06 12:09:18', NULL, 1),
(23, 6, 1, 'guru', 'Dipanggil oleh: Muhammad Fadhil Manfa | Dijemput: ayah', 'tiba', NULL, 'dipanggil', 8, '2026-01-06 12:14:43', '2026-01-06 12:14:48', NULL, 1),
(24, 6, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 9, '2026-01-06 12:25:49', '2026-01-06 12:25:54', NULL, 1),
(25, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 1, '2026-01-07 06:40:21', '2026-01-07 06:41:02', '2026-01-07 06:50:44', 5),
(26, 1, 1, 'ibu', NULL, 'tiba', NULL, 'dibatalkan', 2, '2026-01-07 06:50:44', NULL, NULL, 5),
(27, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 3, '2026-01-07 06:53:34', '2026-01-07 07:07:41', NULL, 5),
(28, 2, 2, 'ojek', 'grab', 'tiba', NULL, 'dipanggil', 4, '2026-01-07 07:07:25', '2026-01-07 07:07:56', NULL, 5),
(29, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 1, '2026-01-08 14:12:33', '2026-01-08 14:12:45', '2026-01-08 14:30:49', 5),
(30, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 2, '2026-01-08 14:30:49', '2026-01-08 14:30:54', '2026-01-08 15:30:24', 5),
(31, 2, 2, 'ibu', NULL, 'tiba', NULL, 'dijemput', 3, '2026-01-08 14:31:13', '2026-01-08 14:31:18', '2026-01-08 15:55:44', 5),
(32, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 4, '2026-01-08 15:30:24', '2026-01-08 15:30:31', '2026-01-08 15:44:04', 5),
(33, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 5, '2026-01-08 15:44:04', '2026-01-08 15:44:09', '2026-01-08 15:54:06', 5),
(34, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dijemput', 6, '2026-01-08 15:54:06', '2026-01-08 15:54:32', '2026-01-08 16:20:31', 5),
(35, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dijemput', 7, '2026-01-08 15:55:44', '2026-01-08 15:56:32', '2026-01-08 16:19:39', 1),
(36, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dijemput', 8, '2026-01-08 16:19:39', '2026-01-08 16:19:55', '2026-01-08 16:22:37', 1),
(37, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 9, '2026-01-08 16:20:31', '2026-01-08 16:23:17', NULL, 1),
(38, 2, 2, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 10, '2026-01-08 16:22:37', '2026-01-08 16:23:32', NULL, 1),
(39, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 11, '2026-01-08 16:25:49', '2026-01-08 16:25:57', NULL, 1),
(40, 3, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 12, '2026-01-08 16:26:29', '2026-01-08 16:27:11', NULL, 1),
(41, 4, 1, 'ibu', NULL, 'tiba', NULL, 'dipanggil', 13, '2026-01-08 16:29:42', '2026-01-08 16:29:58', NULL, 1);

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
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `no_telepon_ortu` varchar(20) DEFAULT NULL,
  `last_pickup_request` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `siswa`
--

INSERT INTO `siswa` (`id`, `nama`, `nama_panggilan`, `kelas_id`, `foto_url`, `username`, `password`, `no_telepon_ortu`, `last_pickup_request`, `created_at`) VALUES
(1, 'Muhammad Rizki', 'Rizki', 1, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Muhammad Rizki&size=200&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf', 'rizki', 'siswa123', NULL, '2026-01-08 16:25:49', '2025-12-28 17:40:41'),
(2, 'Siti Aisyah', 'Aisyah', 1, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Aisyah&size=200&backgroundColor=c0aede', 'aisyah', 'siswa123', NULL, '2026-01-08 16:22:37', '2025-12-28 17:40:41'),
(3, 'Ahmad Fauzi', 'Fauzi', 5, 'https://api.dicebear.com/9.x/thumbs/png?seed=Fauzi&size=200&backgroundColor=d1d4f9', 'fauzi', 'siswa123', NULL, '2026-01-08 16:26:29', '2025-12-28 17:40:41'),
(4, 'Fatimah Zahra', 'Fatimah', 5, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Fatimah&size=200&backgroundColor=ffd5dc', 'fatimah', 'siswa123', NULL, '2026-01-08 16:29:42', '2025-12-28 17:40:41'),
(5, 'Ali Rahman', 'Ali', 9, 'https://api.dicebear.com/9.x/fun-emoji/png?seed=Ali&size=200&backgroundColor=ffdfbf', 'ali', 'siswa123', NULL, NULL, '2025-12-28 17:40:41'),
(6, 'Khadijah', 'Khadijah', 9, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Khadijah&size=200&backgroundColor=b6e3f4', 'khadijah', 'siswa123', NULL, '2026-01-06 12:25:49', '2025-12-28 17:40:41'),
(7, 'Usman Hakim', 'Usman', 13, 'https://api.dicebear.com/9.x/thumbs/png?seed=Usman&size=200&backgroundColor=c0aede', 'usman', 'siswa123', NULL, NULL, '2025-12-28 17:40:41'),
(8, 'Maryam', 'Maryam', 13, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Maryam&size=200&backgroundColor=d1d4f9', 'maryam', 'siswa123', NULL, NULL, '2025-12-28 17:40:41'),
(9, 'Bilal Ibrahim', 'Bilal', 17, 'https://api.dicebear.com/9.x/fun-emoji/png?seed=Bilal&size=200&backgroundColor=ffd5dc', 'bilal', 'siswa123', NULL, NULL, '2025-12-28 17:40:41'),
(10, 'Zainab', 'Zainab', 17, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Zainab&size=200&backgroundColor=ffdfbf', 'zainab', 'siswa123', NULL, NULL, '2025-12-28 17:40:41'),
(11, 'Hamzah Malik', 'Hamzah', 21, 'https://api.dicebear.com/9.x/thumbs/png?seed=Hamzah&size=200&backgroundColor=b6e3f4', 'hamzah', 'siswa123', NULL, NULL, '2025-12-28 17:40:41'),
(12, 'Ruqayyah', 'Ruqayyah', 21, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Ruqayyah&size=200&backgroundColor=c0aede', 'ruqayyah', 'siswa123', NULL, NULL, '2025-12-28 17:40:41');

-- --------------------------------------------------------

--
-- Table structure for table `siswa_settings`
--

CREATE TABLE `siswa_settings` (
  `id` int(11) NOT NULL,
  `siswa_id` int(11) NOT NULL,
  `pickup_reminder_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `minutes_before_pickup` int(11) NOT NULL DEFAULT 15,
  `schedule_change_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `notification_sound` varchar(50) DEFAULT 'Bell',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `siswa_settings`
--

INSERT INTO `siswa_settings` (`id`, `siswa_id`, `pickup_reminder_enabled`, `minutes_before_pickup`, `schedule_change_enabled`, `notification_sound`, `updated_at`) VALUES
(1, 1, 1, 5, 1, 'Bell', '2026-01-08 10:42:21'),
(2, 2, 1, 5, 0, 'Bell', '2026-01-08 10:15:55'),
(4, 3, 1, 5, 1, 'Bell', '2026-01-08 10:42:10');

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

--
-- Dumping data for table `status_penjemputan_harian`
--

INSERT INTO `status_penjemputan_harian` (`id`, `siswa_id`, `tanggal`, `sudah_dijemput`, `waktu_dijemput`, `penjemput`) VALUES
(1, 1, '2026-01-02', 1, '2026-01-02 06:26:22', 'lainnya'),
(3, 2, '2026-01-02', 1, '2026-01-02 06:28:37', 'ayah'),
(4, 3, '2026-01-02', 1, '2026-01-02 03:19:22', 'ayah'),
(5, 1, '2026-01-06', 1, '2026-01-06 12:09:18', 'ayah'),
(6, 2, '2026-01-06', 1, '2026-01-06 12:04:11', 'ayah'),
(7, 6, '2026-01-06', 1, '2026-01-06 12:25:54', 'ayah'),
(8, 1, '2026-01-07', 1, '2026-01-07 07:07:41', 'ayah'),
(9, 2, '2026-01-07', 1, '2026-01-07 07:10:29', 'Manual Entry'),
(10, 1, '2026-01-08', 1, '2026-01-08 16:25:57', 'ayah'),
(11, 2, '2026-01-08', 1, '2026-01-08 16:23:32', 'ayah'),
(12, 3, '2026-01-08', 1, '2026-01-08 16:27:11', 'ayah'),
(13, 4, '2026-01-08', 1, '2026-01-08 16:29:58', 'ibu');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(100) NOT NULL,
  `role` enum('guru','class_viewer') NOT NULL DEFAULT 'guru',
  `nama` varchar(100) NOT NULL,
  `no_telepon` varchar(20) DEFAULT NULL,
  `last_pickup_request` timestamp NULL DEFAULT NULL COMMENT 'Untuk fitur cooldown 10 menit',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `foto` varchar(255) DEFAULT NULL COMMENT 'Path foto profil'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`, `nama`, `no_telepon`, `last_pickup_request`, `created_at`, `updated_at`, `foto`) VALUES
(1, 'guru1', 'guru123', 'guru', 'Ibu Siti Nurhaliza S.Pd', '081234567800', NULL, '2025-12-28 17:40:28', '2025-12-28 17:40:28', NULL),
(2, 'guru2', 'guru123', 'guru', 'Pak Ahmad Dhani S.Pd', '081234567801', NULL, '2025-12-28 17:40:28', '2025-12-28 17:40:28', NULL),
(3, 'kelas1abubakar', 'kelas123', 'class_viewer', '', NULL, NULL, '2025-12-28 17:42:54', '2026-01-08 14:04:53', NULL),
(4, 'fadhil.manfa', 'guru123', 'guru', 'Muhammad Fadhil Manfa', '', NULL, '2025-12-29 14:21:00', '2026-01-06 12:53:01', 'uploads/guru_piket/guru_4_1767703981.jpg');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_antrian_hari_ini`
-- (See below for the actual view)
--
CREATE TABLE `v_antrian_hari_ini` (
`id` int(11)
,`nomor_antrian` int(11)
,`nama_siswa` varchar(100)
,`nama_kelas` varchar(100)
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
,`nama_kelas` varchar(100)
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
-- Indexes for table `guru_session_aktif`
--
ALTER TABLE `guru_session_aktif`
  ADD PRIMARY KEY (`id`),
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
-- Indexes for table `pengaturan_aplikasi`
--
ALTER TABLE `pengaturan_aplikasi`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key_name` (`key_name`);

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
  ADD UNIQUE KEY `idx_siswa_username` (`username`),
  ADD KEY `idx_kelas` (`kelas_id`),
  ADD KEY `idx_nama` (`nama`);

--
-- Indexes for table `siswa_settings`
--
ALTER TABLE `siswa_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_siswa` (`siswa_id`);

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
-- AUTO_INCREMENT for table `guru_session_aktif`
--
ALTER TABLE `guru_session_aktif`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=166;

--
-- AUTO_INCREMENT for table `jadwal_kelas`
--
ALTER TABLE `jadwal_kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=162;

--
-- AUTO_INCREMENT for table `kelas`
--
ALTER TABLE `kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `login_kelas`
--
ALTER TABLE `login_kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `orang_tua_siswa`
--
ALTER TABLE `orang_tua_siswa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pengaturan_aplikasi`
--
ALTER TABLE `pengaturan_aplikasi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `permintaan_jemput`
--
ALTER TABLE `permintaan_jemput`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `siswa`
--
ALTER TABLE `siswa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `siswa_settings`
--
ALTER TABLE `siswa_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `status_penjemputan_harian`
--
ALTER TABLE `status_penjemputan_harian`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

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
-- Constraints for table `guru_session_aktif`
--
ALTER TABLE `guru_session_aktif`
  ADD CONSTRAINT `fk_guru_session` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

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
-- Constraints for table `siswa_settings`
--
ALTER TABLE `siswa_settings`
  ADD CONSTRAINT `siswa_settings_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `status_penjemputan_harian`
--
ALTER TABLE `status_penjemputan_harian`
  ADD CONSTRAINT `status_penjemputan_harian_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
