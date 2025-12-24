<?php
/**
 * Edit Siswa - SDIA 28 Sistem Penjemputan
 * File: service/database/edit_siswa.php
 * 
 * Endpoint untuk mengupdate data siswa
 */

// Set header untuk response JSON dan CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Hanya terima method POST atau PUT
if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT'])) {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST atau PUT."
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
        'id' => $_POST['id'] ?? '',
        'nama' => $_POST['nama'] ?? '',
        'nama_panggilan' => $_POST['nama_panggilan'] ?? '',
        'kelas_id' => $_POST['kelas_id'] ?? ''
    ];
}

// Validasi input
$id = (int) ($data['id'] ?? 0);
$nama = trim($data['nama'] ?? '');
$nama_panggilan = trim($data['nama_panggilan'] ?? '');
$kelas_id = (int) ($data['kelas_id'] ?? 0);

if ($id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "ID siswa tidak valid."
    ]);
    exit();
}

if (empty($nama)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Nama siswa harus diisi."
    ]);
    exit();
}

if ($kelas_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Kelas harus dipilih."
    ]);
    exit();
}

// Cek apakah siswa exists
$check_siswa = mysqli_prepare($conn, "SELECT id FROM siswa WHERE id = ?");
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
mysqli_stmt_close($check_siswa);

// Cek apakah kelas exists
$check_kelas = mysqli_prepare($conn, "SELECT id FROM kelas WHERE id = ?");
mysqli_stmt_bind_param($check_kelas, "i", $kelas_id);
mysqli_stmt_execute($check_kelas);
$kelas_result = mysqli_stmt_get_result($check_kelas);

if (mysqli_num_rows($kelas_result) === 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Kelas tidak ditemukan."
    ]);
    mysqli_stmt_close($check_kelas);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($check_kelas);

// Update siswa
$query = "UPDATE siswa SET nama = ?, nama_panggilan = ?, kelas_id = ? WHERE id = ?";
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

mysqli_stmt_bind_param($stmt, "ssii", $nama, $nama_panggilan, $kelas_id, $id);

if (mysqli_stmt_execute($stmt)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Data siswa berhasil diupdate!",
        "data" => [
            "id" => $id,
            "nama" => $nama,
            "nama_panggilan" => $nama_panggilan,
            "kelas_id" => $kelas_id
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengupdate data siswa: " . mysqli_error($conn)
    ]);
}

// Tutup statement dan koneksi
mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
