<?php
/**
 * Delete All Siswa - SDIA 28 Sistem Penjemputan
 * File: service/database/delete_all_siswa.php
 * 
 * Endpoint untuk menghapus SEMUA siswa
 */

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'DELETE'])) {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST atau DELETE."
    ]);
    exit();
}

require_once '../config/koneksi.php';

// Get confirmation from request
$input = file_get_contents("php://input");
$data = json_decode($input, true);

$confirm = $data['confirm'] ?? false;

if ($confirm !== true && $confirm !== 'true') {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Konfirmasi diperlukan untuk menghapus semua siswa."
    ]);
    exit();
}

// Count total siswa before deleting
$count_query = "SELECT COUNT(*) as total FROM siswa";
$count_result = mysqli_query($conn, $count_query);
$total_siswa = mysqli_fetch_assoc($count_result)['total'];

if ($total_siswa == 0) {
    echo json_encode([
        "success" => true,
        "message" => "Tidak ada siswa untuk dihapus.",
        "deleted_count" => 0
    ]);
    mysqli_close($conn);
    exit();
}

// Delete all siswa
$delete_query = "DELETE FROM siswa";
$result = mysqli_query($conn, $delete_query);

if ($result) {
    // Reset auto increment
    mysqli_query($conn, "ALTER TABLE siswa AUTO_INCREMENT = 1");
    
    echo json_encode([
        "success" => true,
        "message" => "Berhasil menghapus {$total_siswa} siswa!",
        "deleted_count" => (int)$total_siswa
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menghapus siswa: " . mysqli_error($conn)
    ]);
}

mysqli_close($conn);
?>
