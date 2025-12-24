<?php
/**
 * Check Session - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/check_session.php
 * 
 * Endpoint untuk memeriksa apakah user masih login
 * Berguna untuk validasi di setiap halaman yang membutuhkan autentikasi
 */

// Set header untuk response JSON dan CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Hanya terima method POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST."
    ]);
    exit();
}

// Include file koneksi database
require_once '../config/koneksi.php';

// Ambil data dari request
$input = file_get_contents("php://input");
$data = json_decode($input, true);

$user_id = (int) ($data['user_id'] ?? 0);
$username = trim($data['username'] ?? '');

if ($user_id <= 0 || empty($username)) {
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "message" => "Sesi tidak valid. Silakan login kembali."
    ]);
    exit();
}

// Verifikasi user di database
$query = "SELECT id, username, nama, role, no_telepon 
          FROM users 
          WHERE id = ? AND username = ? AND role IN ('teacher', 'class_viewer')";

$stmt = mysqli_prepare($conn, $query);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Terjadi kesalahan pada server."
    ]);
    exit();
}

mysqli_stmt_bind_param($stmt, "is", $user_id, $username);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if ($row = mysqli_fetch_assoc($result)) {
    // User valid
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Sesi aktif.",
        "data" => [
            "id" => (int) $row['id'],
            "username" => $row['username'],
            "nama" => $row['nama'],
            "role" => $row['role'],
            "no_telepon" => $row['no_telepon']
        ]
    ]);
} else {
    // User tidak ditemukan
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "message" => "Sesi tidak valid. Silakan login kembali."
    ]);
}

// Tutup statement dan koneksi
mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
