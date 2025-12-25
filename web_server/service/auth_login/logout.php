<?php
/**
 * Backend Logout - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/logout.php
 * 
 * Endpoint untuk proses logout user
 */

// Set header untuk response JSON dan CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include file koneksi database untuk clear session guru
require_once '../config/koneksi.php';

// Ambil user_id dari request jika ada
$input = file_get_contents("php://input");
$data = json_decode($input, true);
$user_id = (int) ($data['user_id'] ?? 0);

// Clear guru session aktif
if ($user_id > 0) {
    // Hapus session untuk user tertentu
    $deleteQuery = "DELETE FROM guru_session_aktif WHERE user_id = ?";
    $stmt = mysqli_prepare($conn, $deleteQuery);
    if ($stmt) {
        mysqli_stmt_bind_param($stmt, "i", $user_id);
        mysqli_stmt_execute($stmt);
        mysqli_stmt_close($stmt);
    }
} else {
    // Jika tidak ada user_id, hapus semua session (fallback)
    mysqli_query($conn, "DELETE FROM guru_session_aktif");
}

mysqli_close($conn);

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Logout berhasil. Session guru telah dihapus."
]);
?>
