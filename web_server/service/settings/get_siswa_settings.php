<?php
/**
 * Get Siswa Settings - SDIA 28 Sistem Penjemputan
 * File: service/settings/get_siswa_settings.php
 * 
 * Endpoint untuk mengambil settings notifikasi per-siswa
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

// Validasi parameter siswa_id
if (!isset($_GET['siswa_id']) || empty($_GET['siswa_id'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter siswa_id diperlukan"
    ]);
    exit();
}

$siswa_id = intval($_GET['siswa_id']);

// Include file koneksi database
require_once '../config/koneksi.php';

// Query untuk mengambil settings siswa
$query = "SELECT 
            pickup_reminder_enabled,
            minutes_before_pickup,
            schedule_change_enabled,
            notification_sound,
            updated_at
          FROM siswa_settings 
          WHERE siswa_id = ?";

$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, "i", $siswa_id);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if ($row = mysqli_fetch_assoc($result)) {
    // Settings ditemukan
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Settings berhasil diambil",
        "data" => [
            "pickup_reminder_enabled" => (bool) $row['pickup_reminder_enabled'],
            "minutes_before_pickup" => (int) $row['minutes_before_pickup'],
            "schedule_change_enabled" => (bool) $row['schedule_change_enabled'],
            "notification_sound" => $row['notification_sound'],
            "updated_at" => $row['updated_at']
        ]
    ]);
} else {
    // Settings belum ada, return default values
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Settings default (belum ada di database)",
        "data" => [
            "pickup_reminder_enabled" => false,
            "minutes_before_pickup" => 15,
            "schedule_change_enabled" => false,
            "notification_sound" => "Bell",
            "updated_at" => null
        ]
    ]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
