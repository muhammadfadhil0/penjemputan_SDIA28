<?php
/**
 * Update Siswa Settings - SDIA 28 Sistem Penjemputan
 * File: service/settings/update_siswa_settings.php
 * 
 * Endpoint untuk update settings notifikasi per-siswa
 * Menggunakan INSERT ... ON DUPLICATE KEY UPDATE untuk create/update
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

// Baca JSON body
$rawData = file_get_contents("php://input");
$data = json_decode($rawData, true);

// Validasi siswa_id
if (!isset($data['siswa_id']) || empty($data['siswa_id'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter siswa_id diperlukan"
    ]);
    exit();
}

$siswa_id = intval($data['siswa_id']);
$pickup_reminder_enabled = isset($data['pickup_reminder_enabled']) ? ($data['pickup_reminder_enabled'] ? 1 : 0) : 0;
$minutes_before_pickup = isset($data['minutes_before_pickup']) ? intval($data['minutes_before_pickup']) : 15;
$schedule_change_enabled = isset($data['schedule_change_enabled']) ? ($data['schedule_change_enabled'] ? 1 : 0) : 0;
$notification_sound = isset($data['notification_sound']) ? $data['notification_sound'] : 'Bell';

// Include file koneksi database
require_once '../config/koneksi.php';

// Cek apakah siswa_id valid
$checkQuery = "SELECT id FROM siswa WHERE id = ?";
$checkStmt = mysqli_prepare($conn, $checkQuery);
mysqli_stmt_bind_param($checkStmt, "i", $siswa_id);
mysqli_stmt_execute($checkStmt);
$checkResult = mysqli_stmt_get_result($checkStmt);

if (mysqli_num_rows($checkResult) === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Siswa dengan ID $siswa_id tidak ditemukan"
    ]);
    mysqli_stmt_close($checkStmt);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($checkStmt);

// Insert or Update settings
$query = "INSERT INTO siswa_settings 
            (siswa_id, pickup_reminder_enabled, minutes_before_pickup, schedule_change_enabled, notification_sound)
          VALUES (?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE 
            pickup_reminder_enabled = VALUES(pickup_reminder_enabled),
            minutes_before_pickup = VALUES(minutes_before_pickup),
            schedule_change_enabled = VALUES(schedule_change_enabled),
            notification_sound = VALUES(notification_sound)";

$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, "iiiss", 
    $siswa_id, 
    $pickup_reminder_enabled, 
    $minutes_before_pickup, 
    $schedule_change_enabled, 
    $notification_sound
);

if (mysqli_stmt_execute($stmt)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Settings berhasil disimpan",
        "data" => [
            "siswa_id" => $siswa_id,
            "pickup_reminder_enabled" => (bool) $pickup_reminder_enabled,
            "minutes_before_pickup" => $minutes_before_pickup,
            "schedule_change_enabled" => (bool) $schedule_change_enabled,
            "notification_sound" => $notification_sound
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menyimpan settings: " . mysqli_error($conn)
    ]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
