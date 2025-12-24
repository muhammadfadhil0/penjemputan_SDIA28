<?php
/**
 * Get All Siswa - SDIA 28 Sistem Penjemputan
 * File: service/database/get_siswa.php
 * 
 * Endpoint untuk mengambil semua data siswa dengan info kelas
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

// Include file koneksi database
require_once '../config/koneksi.php';

// Query untuk mengambil semua siswa dengan nama kelas
$query = "SELECT 
            s.id,
            s.nama,
            s.nama_panggilan,
            s.kelas_id,
            k.nama_kelas,
            k.tingkat,
            s.foto_url,
            s.created_at
          FROM siswa s
          LEFT JOIN kelas k ON s.kelas_id = k.id
          ORDER BY k.tingkat ASC, k.nama_kelas ASC, s.nama ASC";

$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengambil data siswa: " . mysqli_error($conn)
    ]);
    mysqli_close($conn);
    exit();
}

// Ambil semua data
$students = [];
while ($row = mysqli_fetch_assoc($result)) {
    $students[] = [
        "id" => (int) $row['id'],
        "nama" => $row['nama'],
        "nama_panggilan" => $row['nama_panggilan'] ?? '',
        "kelas_id" => (int) $row['kelas_id'],
        "nama_kelas" => $row['nama_kelas'],
        "tingkat" => (int) $row['tingkat'],
        "foto_url" => $row['foto_url'],
        "created_at" => $row['created_at']
    ];
}

// Response sukses
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Data siswa berhasil diambil",
    "total" => count($students),
    "data" => $students
]);

// Tutup koneksi
mysqli_close($conn);
?>
