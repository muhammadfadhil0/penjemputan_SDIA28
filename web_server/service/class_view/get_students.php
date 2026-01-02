<?php
/**
 * Backend Class View - Get Students by Kelas
 * File: service/class_view/get_students.php
 * 
 * Endpoint untuk mengambil data siswa berdasarkan kelas_id
 * dengan status penjemputan hari ini
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

// Ambil kelas_id dari parameter
$kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : 0;

if ($kelas_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter kelas_id diperlukan."
    ]);
    exit();
}

// Ambil data kelas
$queryKelas = "SELECT id, nama_kelas, tingkat, tahun_ajaran FROM kelas WHERE id = ?";
$stmtKelas = mysqli_prepare($conn, $queryKelas);
mysqli_stmt_bind_param($stmtKelas, "i", $kelas_id);
mysqli_stmt_execute($stmtKelas);
$resultKelas = mysqli_stmt_get_result($stmtKelas);
$kelas = mysqli_fetch_assoc($resultKelas);
mysqli_stmt_close($stmtKelas);

if (!$kelas) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Kelas tidak ditemukan."
    ]);
    exit();
}

// Set timezone ke WIB (Jakarta)
date_default_timezone_set('Asia/Jakarta');

// Ambil data siswa dengan status penjemputan hari ini
$today = date('Y-m-d');
$querySiswa = "SELECT 
                    s.id,
                    s.nama,
                    s.nama_panggilan,
                    s.foto_url,
                    COALESCE(sph.sudah_dijemput, 0) as sudah_dijemput,
                    sph.waktu_dijemput,
                    sph.penjemput
               FROM siswa s
               LEFT JOIN status_penjemputan_harian sph 
                    ON s.id = sph.siswa_id AND sph.tanggal = ?
               WHERE s.kelas_id = ?
               ORDER BY s.nama ASC";

$stmtSiswa = mysqli_prepare($conn, $querySiswa);
mysqli_stmt_bind_param($stmtSiswa, "si", $today, $kelas_id);
mysqli_stmt_execute($stmtSiswa);
$resultSiswa = mysqli_stmt_get_result($stmtSiswa);

$students = [];
while ($row = mysqli_fetch_assoc($resultSiswa)) {
    $students[] = [
        "id" => (int)$row['id'],
        "nama" => $row['nama'],
        "nama_panggilan" => $row['nama_panggilan'] ?? $row['nama'],
        "foto_url" => $row['foto_url'],
        "sudah_dijemput" => (bool)$row['sudah_dijemput'],
        "waktu_dijemput" => $row['waktu_dijemput'],
        "penjemput" => $row['penjemput']
    ];
}

mysqli_stmt_close($stmtSiswa);

// Hitung statistik
$totalSiswa = count($students);
$sudahDijemput = count(array_filter($students, fn($s) => $s['sudah_dijemput']));
$belumDijemput = $totalSiswa - $sudahDijemput;

// Response
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Data siswa berhasil diambil.",
    "tanggal_server" => $today, // untuk debugging
    "data" => [
        "kelas" => [
            "id" => (int)$kelas['id'],
            "nama_kelas" => $kelas['nama_kelas'],
            "tingkat" => (int)$kelas['tingkat'],
            "tahun_ajaran" => $kelas['tahun_ajaran']
        ],
        "statistik" => [
            "total" => $totalSiswa,
            "sudah_dijemput" => $sudahDijemput,
            "belum_dijemput" => $belumDijemput
        ],
        "students" => $students
    ]
]);

mysqli_close($conn);
?>
