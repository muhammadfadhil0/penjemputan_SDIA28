<?php
/**
 * Get Active Teacher - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/get_active_teacher.php
 * 
 * Endpoint untuk mendapatkan guru yang sedang bertugas
 * Membaca dari file active_session.json (file-based heartbeat)
 * 
 * Aturan:
 * - Timeout: 10 detik (jika tidak ada heartbeat dalam 10 detik = tidak aktif)
 * - Auto-reset tengah malam: timestamp dari hari sebelumnya dianggap expired
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

// Path file active session
$sessionFile = __DIR__ . '/../../active_session.json';

// Cek apakah file ada
if (!file_exists($sessionFile)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "has_active_teacher" => false,
        "data" => null
    ]);
    exit();
}

// Baca file
$content = file_get_contents($sessionFile);
$session = json_decode($content, true);

// Validasi data
if (!$session || !isset($session['timestamp']) || !isset($session['date'])) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "has_active_teacher" => false,
        "data" => null
    ]);
    exit();
}

// Cek apakah dari hari ini (auto-reset tengah malam)
$today = date('Y-m-d');
if ($session['date'] !== $today) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "has_active_teacher" => false,
        "data" => null,
        "reason" => "Session expired (previous day)"
    ]);
    exit();
}

// Cek apakah masih dalam timeout (10 detik)
$currentTime = time();
$lastHeartbeat = (int) $session['timestamp'];
$timeDiff = $currentTime - $lastHeartbeat;
$timeout = 10; // 10 detik

if ($timeDiff > $timeout) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "has_active_teacher" => false,
        "data" => null,
        "reason" => "Heartbeat timeout ({$timeDiff}s > {$timeout}s)"
    ]);
    exit();
}

// Guru aktif
http_response_code(200);
echo json_encode([
    "success" => true,
    "has_active_teacher" => true,
    "data" => [
        "id" => (int) $session['user_id'],
        "nama" => $session['nama'],
        "role" => $session['role'] ?? 'guru',
        "foto" => $session['foto'] ?? ''
    ],
    "last_heartbeat" => $timeDiff . "s ago"
]);
?>
