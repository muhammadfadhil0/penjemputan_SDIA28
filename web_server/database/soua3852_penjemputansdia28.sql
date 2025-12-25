-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Dec 25, 2025 at 09:59 PM
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
(37, 2, '2025-12-25 14:28:06', '2025-12-25 14:28:06');

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
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_holiday` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Status libur: 0=aktif, 1=libur'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `jadwal_kelas`
--

INSERT INTO `jadwal_kelas` (`id`, `kelas_id`, `hari`, `jam_masuk`, `jam_pulang`, `created_at`, `updated_at`, `is_holiday`) VALUES
(1, 5, 'senin', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20', 0),
(2, 5, 'selasa', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20', 0),
(3, 5, 'rabu', '07:00:00', '14:30:00', '2025-12-22 08:51:20', '2025-12-24 08:32:54', 0),
(4, 5, 'kamis', '07:00:00', '21:07:00', '2025-12-22 08:51:20', '2025-12-25 14:00:00', 0),
(5, 5, 'jumat', '07:00:00', '11:30:00', '2025-12-22 08:51:20', '2025-12-22 08:51:20', 0),
(6, 1, 'senin', '07:00:00', '11:30:00', '2025-12-24 08:27:28', '2025-12-25 07:52:46', 0),
(7, 7, 'kamis', '07:00:00', '21:34:00', '2025-12-25 14:28:27', '2025-12-25 14:28:27', 0),
(8, 1, 'kamis', '07:00:00', '21:30:00', '2025-12-25 14:29:16', '2025-12-25 14:29:16', 0),
(9, 7, 'rabu', '07:00:00', '21:00:00', '2025-12-25 14:32:10', '2025-12-25 14:32:10', 0),
(10, 7, 'jumat', '07:00:00', '21:00:00', '2025-12-25 14:32:29', '2025-12-25 14:32:29', 0),
(11, 2, 'senin', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(12, 13, 'senin', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(13, 14, 'senin', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(14, 1, 'selasa', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(15, 2, 'selasa', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(16, 13, 'selasa', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(17, 14, 'selasa', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(18, 1, 'rabu', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(19, 2, 'rabu', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(20, 13, 'rabu', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(21, 14, 'rabu', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(22, 2, 'kamis', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(23, 13, 'kamis', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(24, 14, 'kamis', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(25, 1, 'jumat', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(26, 2, 'jumat', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(27, 13, 'jumat', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(28, 14, 'jumat', '07:00:00', '11:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(42, 3, 'senin', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(43, 4, 'senin', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(44, 15, 'senin', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(45, 16, 'senin', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(46, 3, 'selasa', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(47, 4, 'selasa', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(48, 15, 'selasa', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(49, 16, 'selasa', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(50, 3, 'rabu', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(51, 4, 'rabu', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(52, 15, 'rabu', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(53, 16, 'rabu', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(54, 3, 'kamis', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(55, 4, 'kamis', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(56, 15, 'kamis', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(57, 16, 'kamis', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(58, 3, 'jumat', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(59, 4, 'jumat', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(60, 15, 'jumat', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(61, 16, 'jumat', '07:00:00', '12:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(73, 6, 'senin', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(74, 17, 'senin', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(75, 18, 'senin', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(76, 6, 'selasa', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(77, 17, 'selasa', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(78, 18, 'selasa', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(79, 6, 'rabu', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(80, 17, 'rabu', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(81, 18, 'rabu', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(82, 6, 'kamis', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(83, 17, 'kamis', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(84, 18, 'kamis', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(85, 6, 'jumat', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(86, 17, 'jumat', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(87, 18, 'jumat', '07:00:00', '12:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(88, 7, 'senin', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(89, 8, 'senin', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(90, 19, 'senin', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(91, 20, 'senin', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(92, 7, 'selasa', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(93, 8, 'selasa', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(94, 19, 'selasa', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(95, 20, 'selasa', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(96, 8, 'rabu', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(97, 19, 'rabu', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(98, 20, 'rabu', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(99, 8, 'kamis', '07:00:00', '21:00:00', '2025-12-25 14:54:49', '2025-12-25 14:56:29', 0),
(100, 19, 'kamis', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(101, 20, 'kamis', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(102, 8, 'jumat', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(103, 19, 'jumat', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(104, 20, 'jumat', '07:00:00', '13:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(119, 9, 'senin', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(120, 10, 'senin', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(121, 21, 'senin', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(122, 22, 'senin', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(123, 9, 'selasa', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(124, 10, 'selasa', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(125, 21, 'selasa', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(126, 22, 'selasa', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(127, 9, 'rabu', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(128, 10, 'rabu', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(129, 21, 'rabu', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(130, 22, 'rabu', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(131, 9, 'kamis', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(132, 10, 'kamis', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(133, 21, 'kamis', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(134, 22, 'kamis', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(135, 9, 'jumat', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(136, 10, 'jumat', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(137, 21, 'jumat', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(138, 22, 'jumat', '07:00:00', '13:30:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(150, 11, 'senin', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(151, 12, 'senin', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(152, 23, 'senin', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(153, 11, 'selasa', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(154, 12, 'selasa', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(155, 23, 'selasa', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(156, 11, 'rabu', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(157, 12, 'rabu', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(158, 23, 'rabu', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(159, 11, 'kamis', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(160, 12, 'kamis', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(161, 23, 'kamis', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(162, 11, 'jumat', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(163, 12, 'jumat', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0),
(164, 23, 'jumat', '07:00:00', '14:00:00', '2025-12-25 14:54:49', '2025-12-25 14:54:49', 0);

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
(12, '6B', 6, '2024/2025', '2025-12-22 08:51:20'),
(13, '1C', 1, '2024/2025', '2025-12-25 14:54:49'),
(14, '1D', 1, '2024/2025', '2025-12-25 14:54:49'),
(15, '2C', 2, '2024/2025', '2025-12-25 14:54:49'),
(16, '2D', 2, '2024/2025', '2025-12-25 14:54:49'),
(17, '3C', 3, '2024/2025', '2025-12-25 14:54:49'),
(18, '3D', 3, '2024/2025', '2025-12-25 14:54:49'),
(19, '4C', 4, '2024/2025', '2025-12-25 14:54:49'),
(20, '4D', 4, '2024/2025', '2025-12-25 14:54:49'),
(21, '5C', 5, '2024/2025', '2025-12-25 14:54:49'),
(22, '5D', 5, '2024/2025', '2025-12-25 14:54:49'),
(23, '6C', 6, '2024/2025', '2025-12-25 14:54:49');

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

--
-- Dumping data for table `permintaan_jemput`
--

INSERT INTO `permintaan_jemput` (`id`, `siswa_id`, `user_id`, `penjemput`, `penjemput_detail`, `estimasi_waktu`, `waktu_estimasi`, `status`, `nomor_antrian`, `waktu_request`, `waktu_dipanggil`, `waktu_dijemput`) VALUES
(1, 1, 1, 'ayah', NULL, 'tiba', NULL, 'dipanggil', 1, '2025-12-25 08:07:19', '2025-12-25 08:07:39', NULL),
(2, 4, 4, 'ibu', NULL, 'tiba', NULL, 'dibatalkan', 2, '2025-12-25 08:08:51', NULL, NULL),
(3, 3, 3, 'ojek', 'maxim', 'tiba', NULL, 'dibatalkan', 3, '2025-12-25 08:09:37', NULL, NULL),
(4, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 4, '2025-12-25 08:48:14', '2025-12-25 08:48:29', NULL),
(5, 3, 3, 'lainnya', 'paman', 'tiba', NULL, 'dibatalkan', 5, '2025-12-25 09:09:30', NULL, NULL),
(6, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 6, '2025-12-25 09:10:07', NULL, NULL),
(7, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 7, '2025-12-25 09:16:41', NULL, NULL),
(8, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 8, '2025-12-25 09:22:15', NULL, NULL),
(9, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 9, '2025-12-25 09:24:24', NULL, NULL),
(10, 3, 3, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 10, '2025-12-25 09:24:50', NULL, NULL),
(11, 3, 3, 'lainnya', 'paman', 'tiba', NULL, 'dipanggil', 11, '2025-12-25 09:25:08', '2025-12-25 09:25:16', NULL),
(12, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 12, '2025-12-25 09:28:55', NULL, NULL),
(13, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 13, '2025-12-25 09:32:55', NULL, NULL),
(14, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 14, '2025-12-25 09:33:22', NULL, NULL),
(15, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 15, '2025-12-25 09:36:22', NULL, NULL),
(16, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 16, '2025-12-25 09:36:47', NULL, NULL),
(17, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 17, '2025-12-25 09:38:13', NULL, NULL),
(18, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 18, '2025-12-25 09:39:31', '2025-12-25 09:39:47', NULL),
(19, 4, 4, 'ojek', 'maxim', 'tiba', NULL, 'dibatalkan', 19, '2025-12-25 10:56:16', '2025-12-25 10:56:27', NULL),
(20, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 20, '2025-12-25 11:51:22', NULL, NULL),
(21, 4, 4, 'ayah', NULL, 'tiba', NULL, 'dibatalkan', 21, '2025-12-25 12:51:38', NULL, NULL);

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
(1, 'Ahmad Farhan Pratama', 'Farhan', 8, NULL, 'siswa_farhan', 'siswa123', NULL, '2025-12-25 08:07:19', '2025-12-22 08:51:20'),
(2, 'Aisyah Putri Ramadhani', 'Aisyah', 5, NULL, 'siswa_aisyah', 'siswa123', NULL, NULL, '2025-12-22 08:51:20'),
(3, 'Budi Santoso', 'Budi', 5, NULL, 'siswa_budi', 'siswa123', NULL, '2025-12-25 09:25:08', '2025-12-22 08:51:20'),
(4, 'Citra Dewi Lestari', 'Citra', 5, 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Citra Dewi Lestari&size=200&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf', 'siswa_citra', 'siswa123', NULL, '2025-12-25 12:51:38', '2025-12-22 08:51:20'),
(5, 'Dimas Prasetya', 'Dimas', 5, NULL, 'siswa_dimas', 'siswa123', NULL, NULL, '2025-12-22 08:51:20');

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
  `role` enum('guru','class_viewer') NOT NULL DEFAULT 'guru',
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
(1, 'siri.rofikah', 'guru123', 'guru', 'Siri Rofikah S.Pd', '081234567890', NULL, '2025-12-22 08:51:20', '2025-12-24 09:10:40'),
(2, 'ahmad.fadil', 'guru123', 'guru', 'Ahmad Fadil S.Pd', '081234567891', NULL, '2025-12-22 08:51:20', '2025-12-24 09:10:40'),
(3, 'bapak.farhan', 'ortu123', '', 'Bapak Farhan', '081234567892', NULL, '2025-12-22 08:51:20', '2025-12-22 08:51:20'),
(4, 'ibu.farhan', 'ortu123', '', 'Ibu Farhan', '081234567893', NULL, '2025-12-22 08:51:20', '2025-12-22 08:51:20');

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `jadwal_kelas`
--
ALTER TABLE `jadwal_kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=165;

--
-- AUTO_INCREMENT for table `kelas`
--
ALTER TABLE `kelas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

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
-- Constraints for table `status_penjemputan_harian`
--
ALTER TABLE `status_penjemputan_harian`
  ADD CONSTRAINT `status_penjemputan_harian_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
