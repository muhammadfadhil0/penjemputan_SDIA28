<?php
/**
 * Backend Class View - Get Pickup History by Kelas
 * File: service/class_view/get_class_history.php
 * 
 * Endpoint untuk mengambil riwayat penjemputan berdasarkan kelas_id hari ini
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

// Set timezone ke WIB (Jakarta)
date_default_timezone_set('Asia/Jakarta');

// Ambil kelas_id dari parameter
$kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : 0;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;

if ($kelas_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter kelas_id diperlukan."
    ]);
    exit();
}

$today = date('Y-m-d');

// Query riwayat penjemputan hari ini berdasarkan kelas
$query = "SELECT 
            pj.id,
            pj.siswa_id,
            pj.penjemput,
            pj.penjemput_detail,
            pj.status,
            pj.waktu_request,
            pj.waktu_dipanggil,
            pj.waktu_dijemput,
            s.nama AS nama_siswa,
            s.nama_panggilan
          FROM permintaan_jemput pj
          JOIN siswa s ON pj.siswa_id = s.id
          WHERE s.kelas_id = ? 
            AND DATE(pj.waktu_request) = ?
            AND pj.status IN ('dipanggil', 'dijemput')
          ORDER BY pj.waktu_dipanggil DESC, pj.waktu_request DESC
          LIMIT ?";

$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, "isi", $kelas_id, $today, $limit);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

$history = [];
while ($row = mysqli_fetch_assoc($result)) {
    // Format penjemput display
    $penjemputDisplay = ucfirst($row['penjemput']);
    if ($row['penjemput_detail']) {
        $penjemputDisplay .= ' (' . $row['penjemput_detail'] . ')';
    }
    
    // Format waktu
    $waktu = $row['waktu_dipanggil'] ?? $row['waktu_request'];
    $waktuFormatted = date('H:i', strtotime($waktu));
    
    $history[] = [
        "id" => (int)$row['id'],
        "siswa_id" => (int)$row['siswa_id'],
        "nama_siswa" => $row['nama_panggilan'] ?? $row['nama_siswa'],
        "nama_lengkap" => $row['nama_siswa'],
        "penjemput" => $penjemputDisplay,
        "penjemput_raw" => $row['penjemput'],
        "status" => $row['status'],
        "waktu" => $waktuFormatted,
        "waktu_full" => $waktu
    ];
}

mysqli_stmt_close($stmt);

// Response
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Riwayat penjemputan berhasil diambil.",
    "tanggal" => $today,
    "count" => count($history),
    "data" => $history
]);

mysqli_close($conn);
?>
