<?php
/**
 * Backend Class View - Batch Update Student Pickup Status
 * File: service/class_view/batch_update_pickup.php
 * 
 * Endpoint untuk update status penjemputan beberapa siswa sekaligus
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

// Validasi input - expects array of students with their status
$students = isset($data['students']) ? $data['students'] : [];

if (empty($students)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter students diperlukan (array of {siswa_id, sudah_dijemput})."
    ]);
    exit();
}

$today = date('Y-m-d');
$now = date('Y-m-d H:i:s');

$successCount = 0;
$errorCount = 0;
$errors = [];

foreach ($students as $student) {
    $siswa_id = isset($student['siswa_id']) ? (int)$student['siswa_id'] : 0;
    $sudah_dijemput = isset($student['sudah_dijemput']) ? (bool)$student['sudah_dijemput'] : false;
    $penjemput = isset($student['penjemput']) ? trim($student['penjemput']) : null;

    if ($siswa_id <= 0) {
        $errorCount++;
        $errors[] = "siswa_id tidak valid: " . json_encode($student);
        continue;
    }

    // Cek apakah sudah ada record untuk hari ini
    $queryCekStatus = "SELECT id FROM status_penjemputan_harian WHERE siswa_id = ? AND tanggal = ?";
    $stmtCekStatus = mysqli_prepare($conn, $queryCekStatus);
    mysqli_stmt_bind_param($stmtCekStatus, "is", $siswa_id, $today);
    mysqli_stmt_execute($stmtCekStatus);
    $resultCekStatus = mysqli_stmt_get_result($stmtCekStatus);
    $existingStatus = mysqli_fetch_assoc($resultCekStatus);
    mysqli_stmt_close($stmtCekStatus);

    try {
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
                // Tidak perlu insert jika belum dijemput dan tidak ada record
                $successCount++;
                continue;
            }
            mysqli_stmt_execute($stmtInsert);
            mysqli_stmt_close($stmtInsert);
        }
        $successCount++;
    } catch (Exception $e) {
        $errorCount++;
        $errors[] = "Error pada siswa_id $siswa_id: " . $e->getMessage();
    }
}

// Response
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Batch update selesai. Berhasil: $successCount, Gagal: $errorCount",
    "data" => [
        "success_count" => $successCount,
        "error_count" => $errorCount,
        "errors" => $errors
    ]
]);

mysqli_close($conn);
?>
