<?php
/**
 * Backend Class View - Update Student Pickup Status
 * File: service/class_view/update_pickup_status.php
 * 
 * Endpoint untuk update status penjemputan siswa
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

// Validasi input
$siswa_id = isset($data['siswa_id']) ? (int)$data['siswa_id'] : 0;
$sudah_dijemput = isset($data['sudah_dijemput']) ? (bool)$data['sudah_dijemput'] : false;
$penjemput = isset($data['penjemput']) ? trim($data['penjemput']) : null;

if ($siswa_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter siswa_id diperlukan."
    ]);
    exit();
}

// Cek apakah siswa ada
$queryCek = "SELECT id, nama FROM siswa WHERE id = ?";
$stmtCek = mysqli_prepare($conn, $queryCek);
mysqli_stmt_bind_param($stmtCek, "i", $siswa_id);
mysqli_stmt_execute($stmtCek);
$resultCek = mysqli_stmt_get_result($stmtCek);
$siswa = mysqli_fetch_assoc($resultCek);
mysqli_stmt_close($stmtCek);

if (!$siswa) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Siswa tidak ditemukan."
    ]);
    exit();
}

$today = date('Y-m-d');
$now = date('Y-m-d H:i:s');

// Cek apakah sudah ada record untuk hari ini
$queryCekStatus = "SELECT id FROM status_penjemputan_harian WHERE siswa_id = ? AND tanggal = ?";
$stmtCekStatus = mysqli_prepare($conn, $queryCekStatus);
mysqli_stmt_bind_param($stmtCekStatus, "is", $siswa_id, $today);
mysqli_stmt_execute($stmtCekStatus);
$resultCekStatus = mysqli_stmt_get_result($stmtCekStatus);
$existingStatus = mysqli_fetch_assoc($resultCekStatus);
mysqli_stmt_close($stmtCekStatus);

if ($existingStatus) {
    // Update existing record
    if ($sudah_dijemput) {
        $queryUpdate = "UPDATE status_penjemputan_harian 
                        SET sudah_dijemput = 1, waktu_dijemput = ?, penjemput = ?
                        WHERE siswa_id = ? AND tanggal = ?";
        $stmtUpdate = mysqli_prepare($conn, $queryUpdate);
        mysqli_stmt_bind_param($stmtUpdate, "ssis", $now, $penjemput, $siswa_id, $today);
    } else {
        $queryUpdate = "UPDATE status_penjemputan_harian 
                        SET sudah_dijemput = 0, waktu_dijemput = NULL, penjemput = NULL
                        WHERE siswa_id = ? AND tanggal = ?";
        $stmtUpdate = mysqli_prepare($conn, $queryUpdate);
        mysqli_stmt_bind_param($stmtUpdate, "is", $siswa_id, $today);
    }
    mysqli_stmt_execute($stmtUpdate);
    mysqli_stmt_close($stmtUpdate);
} else {
    // Insert new record
    if ($sudah_dijemput) {
        $queryInsert = "INSERT INTO status_penjemputan_harian 
                        (siswa_id, tanggal, sudah_dijemput, waktu_dijemput, penjemput) 
                        VALUES (?, ?, 1, ?, ?)";
        $stmtInsert = mysqli_prepare($conn, $queryInsert);
        mysqli_stmt_bind_param($stmtInsert, "isss", $siswa_id, $today, $now, $penjemput);
    } else {
        $queryInsert = "INSERT INTO status_penjemputan_harian 
                        (siswa_id, tanggal, sudah_dijemput) 
                        VALUES (?, ?, 0)";
        $stmtInsert = mysqli_prepare($conn, $queryInsert);
        mysqli_stmt_bind_param($stmtInsert, "is", $siswa_id, $today);
    }
    mysqli_stmt_execute($stmtInsert);
    mysqli_stmt_close($stmtInsert);
}

// Response
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => $sudah_dijemput 
        ? "Status {$siswa['nama']} berhasil diubah menjadi SUDAH DIJEMPUT." 
        : "Status {$siswa['nama']} berhasil diubah menjadi BELUM DIJEMPUT.",
    "data" => [
        "siswa_id" => $siswa_id,
        "nama" => $siswa['nama'],
        "sudah_dijemput" => $sudah_dijemput,
        "waktu_dijemput" => $sudah_dijemput ? $now : null,
        "penjemput" => $sudah_dijemput ? $penjemput : null
    ]
]);

mysqli_close($conn);
?>
