<?php
/**
 * Get Active Teacher - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/get_active_teacher.php
 * 
 * Endpoint untuk mendapatkan guru yang sedang bertugas
 * Dipanggil oleh aplikasi Flutter untuk menampilkan nama guru aktif
 */

// Set header untuk response JSON dan CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Hanya terima method GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan GET."
    ]);
    exit();
}

// Include file koneksi database
require_once '../config/koneksi.php';

// Query untuk mendapatkan guru aktif
// Hanya ambil session yang heartbeat-nya dalam 1 menit terakhir (menghindari stale session)
$query = "SELECT u.id, u.nama, u.role 
          FROM guru_session_aktif gsa
          JOIN users u ON gsa.user_id = u.id
          WHERE gsa.last_heartbeat >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
          ORDER BY gsa.last_heartbeat DESC
          LIMIT 1";

$result = mysqli_query($conn, $query);

if ($result && $row = mysqli_fetch_assoc($result)) {
    // Ada guru aktif
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "has_active_teacher" => true,
        "data" => [
            "id" => (int) $row['id'],
            "nama" => $row['nama'],
            "role" => $row['role']
        ]
    ]);
} else {
    // Tidak ada guru aktif
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "has_active_teacher" => false,
        "data" => null
    ]);
}

mysqli_close($conn);
?>
