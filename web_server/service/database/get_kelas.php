<?php
/**
 * Get All Kelas - SDIA 28 Sistem Penjemputan
 * File: service/database/get_kelas.php
 * 
 * Endpoint untuk mengambil semua data kelas (untuk dropdown)
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

// Query untuk mengambil semua kelas
$query = "SELECT id, nama_kelas, tingkat, tahun_ajaran 
          FROM kelas 
          ORDER BY tingkat ASC, nama_kelas ASC";

$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengambil data kelas: " . mysqli_error($conn)
    ]);
    mysqli_close($conn);
    exit();
}

// Ambil semua data
$classes = [];
while ($row = mysqli_fetch_assoc($result)) {
    $classes[] = [
        "id" => (int) $row['id'],
        "nama_kelas" => $row['nama_kelas'],
        "tingkat" => (int) $row['tingkat'],
        "tahun_ajaran" => $row['tahun_ajaran']
    ];
}

// Response sukses
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Data kelas berhasil diambil",
    "total" => count($classes),
    "data" => $classes
]);

// Tutup koneksi
mysqli_close($conn);
?>
