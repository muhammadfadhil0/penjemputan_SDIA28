<?php
/**
 * Save/Update Jadwal Kelas - SDIA 28 Sistem Penjemputan
 * File: service/jadwal/save_jadwal.php
 * 
 * Endpoint untuk menyimpan atau update jadwal kelas
 * Method: POST
 * Body JSON: {
 *   "kelas_id": 5,
 *   "hari": "senin",
 *   "jam_masuk": "07:00",
 *   "jam_pulang": "14:30",
 *   "is_holiday": false
 * }
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

// Ambil data JSON dari body request
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Validasi JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Format JSON tidak valid"
    ]);
    mysqli_close($conn);
    exit();
}

// Validasi field yang diperlukan
$required_fields = ['kelas_id', 'hari', 'jam_masuk', 'jam_pulang'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        $missing_fields[] = $field;
    }
}

if (!empty($missing_fields)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Field berikut diperlukan: " . implode(", ", $missing_fields)
    ]);
    mysqli_close($conn);
    exit();
}

// Ambil dan sanitasi data
$kelas_id = (int)$data['kelas_id'];
$hari = strtolower(trim($data['hari']));
$jam_masuk = trim($data['jam_masuk']);
$jam_pulang = trim($data['jam_pulang']);
$is_holiday = isset($data['is_holiday']) ? (bool)$data['is_holiday'] : false;

// Validasi hari
$valid_days = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];
if (!in_array($hari, $valid_days)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Hari tidak valid. Pilihan: senin, selasa, rabu, kamis, jumat, sabtu"
    ]);
    mysqli_close($conn);
    exit();
}

// Validasi format waktu (HH:mm)
if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $jam_masuk) || 
    !preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $jam_pulang)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Format waktu tidak valid. Gunakan format HH:mm"
    ]);
    mysqli_close($conn);
    exit();
}

// Validasi kelas_id ada di database
$check_kelas = mysqli_prepare($conn, "SELECT id FROM kelas WHERE id = ?");
mysqli_stmt_bind_param($check_kelas, "i", $kelas_id);
mysqli_stmt_execute($check_kelas);
$result_kelas = mysqli_stmt_get_result($check_kelas);

if (mysqli_num_rows($result_kelas) === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Kelas dengan ID $kelas_id tidak ditemukan"
    ]);
    mysqli_stmt_close($check_kelas);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($check_kelas);

// Cek apakah jadwal sudah ada (untuk update) atau belum (untuk insert)
$check_query = "SELECT id FROM jadwal_kelas WHERE kelas_id = ? AND hari = ?";
$check_stmt = mysqli_prepare($conn, $check_query);
mysqli_stmt_bind_param($check_stmt, "is", $kelas_id, $hari);
mysqli_stmt_execute($check_stmt);
$check_result = mysqli_stmt_get_result($check_stmt);
$existing = mysqli_fetch_assoc($check_result);
mysqli_stmt_close($check_stmt);

// Konversi is_holiday ke integer untuk database
$is_holiday_int = $is_holiday ? 1 : 0;

if ($existing) {
    // Update jadwal yang sudah ada
    $update_query = "UPDATE jadwal_kelas SET jam_masuk = ?, jam_pulang = ?, is_holiday = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?";
    $update_stmt = mysqli_prepare($conn, $update_query);
    mysqli_stmt_bind_param($update_stmt, "ssii", $jam_masuk, $jam_pulang, $is_holiday_int, $existing['id']);
    
    if (mysqli_stmt_execute($update_stmt)) {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Jadwal berhasil diperbarui",
            "action" => "update",
            "data" => [
                "id" => (int)$existing['id'],
                "kelas_id" => $kelas_id,
                "hari" => $hari,
                "jam_masuk" => $jam_masuk,
                "jam_pulang" => $jam_pulang,
                "is_holiday" => $is_holiday
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal memperbarui jadwal: " . mysqli_error($conn)
        ]);
    }
    mysqli_stmt_close($update_stmt);
} else {
    // Insert jadwal baru
    $insert_query = "INSERT INTO jadwal_kelas (kelas_id, hari, jam_masuk, jam_pulang, is_holiday) VALUES (?, ?, ?, ?, ?)";
    $insert_stmt = mysqli_prepare($conn, $insert_query);
    mysqli_stmt_bind_param($insert_stmt, "isssi", $kelas_id, $hari, $jam_masuk, $jam_pulang, $is_holiday_int);
    
    if (mysqli_stmt_execute($insert_stmt)) {
        $new_id = mysqli_insert_id($conn);
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "Jadwal berhasil ditambahkan",
            "action" => "insert",
            "data" => [
                "id" => $new_id,
                "kelas_id" => $kelas_id,
                "hari" => $hari,
                "jam_masuk" => $jam_masuk,
                "jam_pulang" => $jam_pulang,
                "is_holiday" => $is_holiday
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal menambahkan jadwal: " . mysqli_error($conn)
        ]);
    }
    mysqli_stmt_close($insert_stmt);
}

// Tutup koneksi
mysqli_close($conn);
?>
