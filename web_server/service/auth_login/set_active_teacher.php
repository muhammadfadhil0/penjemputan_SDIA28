<?php
/**
 * Set Active Teacher - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/set_active_teacher.php
 * 
 * Endpoint untuk set guru yang sedang aktif di web dashboard
 * Dipanggil saat guru login/membuka halaman dashboard
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

if ($user_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "User ID tidak valid."
    ]);
    exit();
}

// Verifikasi user adalah guru
$checkQuery = "SELECT id, nama FROM users WHERE id = ? AND role = 'guru'";
$checkStmt = mysqli_prepare($conn, $checkQuery);

if (!$checkStmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Terjadi kesalahan pada server."
    ]);
    exit();
}

mysqli_stmt_bind_param($checkStmt, "i", $user_id);
mysqli_stmt_execute($checkStmt);
$checkResult = mysqli_stmt_get_result($checkStmt);

if (!mysqli_fetch_assoc($checkResult)) {
    mysqli_stmt_close($checkStmt);
    http_response_code(403);
    echo json_encode([
        "success" => false,
        "message" => "User bukan guru yang valid."
    ]);
    exit();
}
mysqli_stmt_close($checkStmt);

// Hapus semua session active sebelumnya (hanya satu guru yang aktif)
$deleteQuery = "DELETE FROM guru_session_aktif";
mysqli_query($conn, $deleteQuery);

// Insert session baru
$insertQuery = "INSERT INTO guru_session_aktif (user_id, login_time, last_heartbeat) VALUES (?, NOW(), NOW())";
$insertStmt = mysqli_prepare($conn, $insertQuery);

if (!$insertStmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Terjadi kesalahan pada server."
    ]);
    exit();
}

mysqli_stmt_bind_param($insertStmt, "i", $user_id);

if (mysqli_stmt_execute($insertStmt)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Guru aktif berhasil diset."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menyimpan session guru."
    ]);
}

mysqli_stmt_close($insertStmt);
mysqli_close($conn);
?>
