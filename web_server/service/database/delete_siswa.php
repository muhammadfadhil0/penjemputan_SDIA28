<?php
/**
 * Delete Siswa - SDIA 28 Sistem Penjemputan
 * File: service/database/delete_siswa.php
 * 
 * Endpoint untuk menghapus siswa
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

// Hanya terima method POST atau DELETE
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

// Jika data tidak dalam format JSON, coba ambil dari form data atau query string
if (!$data) {
    $data = [
        'id' => $_POST['id'] ?? $_GET['id'] ?? ''
    ];
}

// Validasi input
$id = (int) ($data['id'] ?? 0);

if ($id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "ID siswa tidak valid."
    ]);
    exit();
}

// Cek apakah siswa exists
$check_siswa = mysqli_prepare($conn, "SELECT id, nama FROM siswa WHERE id = ?");
mysqli_stmt_bind_param($check_siswa, "i", $id);
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
mysqli_stmt_close($check_siswa);

// Delete siswa
$query = "DELETE FROM siswa WHERE id = ?";
$stmt = mysqli_prepare($conn, $query);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Terjadi kesalahan pada server."
    ]);
    mysqli_close($conn);
    exit();
}

mysqli_stmt_bind_param($stmt, "i", $id);

if (mysqli_stmt_execute($stmt)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Siswa '" . $siswa['nama'] . "' berhasil dihapus!",
        "data" => [
            "id" => $id,
            "nama" => $siswa['nama']
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menghapus siswa: " . mysqli_error($conn)
    ]);
}

// Tutup statement dan koneksi
mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
