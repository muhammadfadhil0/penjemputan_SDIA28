<?php
/**
 * Heartbeat Service - SDIA 28 Sistem Penjemputan
 * File: service/heartbeat/heartbeat.php
 * 
 * Endpoint untuk menerima heartbeat dari web dashboard
 * Menyimpan status aktif ke file JSON
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

// Ambil input JSON
$input = json_decode(file_get_contents("php://input"), true);

if (!$input || !isset($input['user_id']) || !isset($input['nama'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "user_id dan nama diperlukan."
    ]);
    exit();
}

// Path file active session (di folder root web_server)
$sessionFile = __DIR__ . '/../../active_session.json';

// Data yang akan disimpan
$sessionData = [
    "user_id" => (int) $input['user_id'],
    "nama" => $input['nama'],
    "role" => $input['role'] ?? 'guru',
    "foto" => $input['foto'] ?? '',
    "timestamp" => time(),
    "date" => date('Y-m-d')
];

// Simpan ke file
$result = file_put_contents($sessionFile, json_encode($sessionData, JSON_PRETTY_PRINT));

if ($result !== false) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Heartbeat diterima."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menyimpan status."
    ]);
}
?>
