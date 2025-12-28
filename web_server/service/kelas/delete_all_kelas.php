<?php
/**
 * Delete All Kelas - SDIA 28 Sistem Penjemputan
 * File: service/kelas/delete_all_kelas.php
 * 
 * Endpoint untuk menghapus SEMUA kelas
 * PERINGATAN: Ini akan menghapus semua siswa terkait juga!
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
$delete_students = $data['delete_students'] ?? false;

if ($confirm !== true && $confirm !== 'true') {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Konfirmasi diperlukan untuk menghapus semua kelas."
    ]);
    exit();
}

// Count total kelas and siswa
$count_kelas = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) as total FROM kelas"))['total'];
$count_siswa = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) as total FROM siswa"))['total'];

if ($count_kelas == 0) {
    echo json_encode([
        "success" => true,
        "message" => "Tidak ada kelas untuk dihapus.",
        "deleted_kelas" => 0,
        "deleted_siswa" => 0
    ]);
    mysqli_close($conn);
    exit();
}

// Check if there are students
if ($count_siswa > 0 && !$delete_students) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Masih ada {$count_siswa} siswa terdaftar. Set 'delete_students' ke true untuk menghapus siswa juga."
    ]);
    mysqli_close($conn);
    exit();
}

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Delete all siswa first (due to foreign key)
    if ($count_siswa > 0) {
        $delete_siswa = mysqli_query($conn, "DELETE FROM siswa");
        if (!$delete_siswa) {
            throw new Exception("Gagal menghapus siswa: " . mysqli_error($conn));
        }
        mysqli_query($conn, "ALTER TABLE siswa AUTO_INCREMENT = 1");
    }
    
    // Delete all kelas
    $delete_kelas = mysqli_query($conn, "DELETE FROM kelas");
    if (!$delete_kelas) {
        throw new Exception("Gagal menghapus kelas: " . mysqli_error($conn));
    }
    mysqli_query($conn, "ALTER TABLE kelas AUTO_INCREMENT = 1");
    
    mysqli_commit($conn);
    
    echo json_encode([
        "success" => true,
        "message" => "Berhasil menghapus {$count_kelas} kelas" . ($count_siswa > 0 ? " dan {$count_siswa} siswa" : "") . "!",
        "deleted_kelas" => (int)$count_kelas,
        "deleted_siswa" => (int)$count_siswa
    ]);
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}

mysqli_close($conn);
?>
