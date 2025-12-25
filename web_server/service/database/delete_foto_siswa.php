<?php
/**
 * Delete Foto Siswa - SDIA 28 Sistem Penjemputan
 * File: service/database/delete_foto_siswa.php
 * 
 * Endpoint untuk menghapus foto profil siswa
 */

// Set header untuk response JSON dan CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Terima method POST atau DELETE
if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'DELETE'])) {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST atau DELETE."
    ]);
    exit();
}

// Include file koneksi database
require_once '../config/koneksi.php';

// Ambil data dari request
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Jika data tidak dalam format JSON, coba ambil dari form data
if (!$data) {
    $data = [
        'siswa_id' => $_POST['siswa_id'] ?? ''
    ];
}

// Validasi input
$siswa_id = (int) ($data['siswa_id'] ?? 0);

if ($siswa_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "ID siswa tidak valid."
    ]);
    exit();
}

// Ambil foto_url lama
$check_siswa = mysqli_prepare($conn, "SELECT id, foto_url FROM siswa WHERE id = ?");
mysqli_stmt_bind_param($check_siswa, "i", $siswa_id);
mysqli_stmt_execute($check_siswa);
$siswa_result = mysqli_stmt_get_result($check_siswa);

if (mysqli_num_rows($siswa_result) === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Siswa tidak ditemukan."
    ]);
    mysqli_stmt_close($check_siswa);
    mysqli_close($conn);
    exit();
}

$siswa = mysqli_fetch_assoc($siswa_result);
$old_foto_url = $siswa['foto_url'];
mysqli_stmt_close($check_siswa);

// Hapus file foto jika ada
if (!empty($old_foto_url)) {
    // Konversi URL ke path file
    $file_path = '../../' . str_replace('https://soulhbc.com/penjemputan/', '', $old_foto_url);
    if (file_exists($file_path)) {
        unlink($file_path);
    }
}

// Update database - set foto_url ke NULL
$update_query = "UPDATE siswa SET foto_url = NULL WHERE id = ?";
$update_stmt = mysqli_prepare($conn, $update_query);
mysqli_stmt_bind_param($update_stmt, "i", $siswa_id);

if (mysqli_stmt_execute($update_stmt)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Foto profil berhasil dihapus!"
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menghapus foto dari database."
    ]);
}

mysqli_stmt_close($update_stmt);
mysqli_close($conn);
?>
