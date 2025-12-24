<?php
/**
 * File Konfigurasi Koneksi Database
 * SDIA 28 - Sistem Penjemputan Siswa
 */

// Konfigurasi koneksi ke database
$host = "localhost"; // Host MySQL
$db_username = "soua3852_admin"; // Username MySQL
$db_password = "kemambuan"; // Password MySQL
$database = "soua3852_penjemputansdia28"; // Nama Database

// Buat koneksi ke database
$conn = mysqli_connect($host, $db_username, $db_password, $database);

// Periksa koneksi
if (!$conn) {
    die(json_encode([
        "success" => false,
        "message" => "Koneksi database gagal: " . mysqli_connect_error()
    ]));
}

// Set charset ke UTF-8
mysqli_set_charset($conn, "utf8mb4");
?>