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

// Untuk sisi client, logout hanya perlu menghapus data sesi di localStorage
// Endpoint ini bisa digunakan untuk logging atau invalidasi token di masa depan

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Logout berhasil. Silakan hapus data sesi di browser."
]);
?>
