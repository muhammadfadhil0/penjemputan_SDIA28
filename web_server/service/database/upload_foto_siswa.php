<?php
/**
 * Upload Foto Siswa - SDIA 28 Sistem Penjemputan
 * File: service/database/upload_foto_siswa.php
 * 
 * Endpoint untuk mengupload foto profil siswa
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

// Validasi input
$siswa_id = (int) ($_POST['siswa_id'] ?? 0);

if ($siswa_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "ID siswa tidak valid."
    ]);
    exit();
}

// Cek apakah file di upload
if (!isset($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "File foto tidak ditemukan atau gagal diupload."
    ]);
    exit();
}

$file = $_FILES['foto'];

// Validasi tipe file
$allowed_types = ['image/jpeg', 'image/jpg', 'image/png'];
$file_type = mime_content_type($file['tmp_name']);

if (!in_array($file_type, $allowed_types)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Tipe file tidak didukung. Gunakan JPG atau PNG."
    ]);
    exit();
}

// Validasi ukuran file (max 5MB)
$max_size = 5 * 1024 * 1024;
if ($file['size'] > $max_size) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Ukuran file terlalu besar. Maksimal 5MB."
    ]);
    exit();
}

// Cek apakah siswa exists
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

// Buat direktori upload jika belum ada
$upload_dir = '../../uploads/fotosiswa/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

// Generate nama file unik
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
$new_filename = 'siswa_' . $siswa_id . '_' . time() . '.' . $extension;
$upload_path = $upload_dir . $new_filename;

// Upload file
if (move_uploaded_file($file['tmp_name'], $upload_path)) {
    // Hapus foto lama jika ada
    if (!empty($old_foto_url)) {
        $old_file_path = '../../' . str_replace('https://soulhbc.com/penjemputan/', '', $old_foto_url);
        if (file_exists($old_file_path)) {
            unlink($old_file_path);
        }
    }
    
    // Generate URL foto
    $foto_url = 'https://soulhbc.com/penjemputan/uploads/fotosiswa/' . $new_filename;
    
    // Update database
    $update_query = "UPDATE siswa SET foto_url = ? WHERE id = ?";
    $update_stmt = mysqli_prepare($conn, $update_query);
    mysqli_stmt_bind_param($update_stmt, "si", $foto_url, $siswa_id);
    
    if (mysqli_stmt_execute($update_stmt)) {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Foto profil berhasil diupload!",
            "data" => [
                "foto_url" => $foto_url
            ]
        ]);
    } else {
        // Hapus file yang sudah diupload jika gagal update database
        unlink($upload_path);
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal menyimpan ke database."
        ]);
    }
    mysqli_stmt_close($update_stmt);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengupload file."
    ]);
}

// Tutup koneksi
mysqli_close($conn);
?>
