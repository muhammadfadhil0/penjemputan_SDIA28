<?php
/**
 * Get Jadwal Kelas - SDIA 28 Sistem Penjemputan
 * File: service/jadwal/get_jadwal.php
 * 
 * Endpoint untuk mengambil jadwal berdasarkan tingkat kelas
 * Method: GET
 * Parameter: tingkat (1-6) atau kelas_id
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

// Ambil parameter
$tingkat = isset($_GET['tingkat']) ? (int)$_GET['tingkat'] : null;
$kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : null;

// Validasi parameter
if (!$tingkat && !$kelas_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter 'tingkat' atau 'kelas_id' diperlukan."
    ]);
    mysqli_close($conn);
    exit();
}

// Jika tingkat diberikan, ambil semua kelas_id di tingkat tersebut
$kelas_ids = [];
if ($tingkat) {
    $query_kelas = "SELECT id FROM kelas WHERE tingkat = ?";
    $stmt_kelas = mysqli_prepare($conn, $query_kelas);
    mysqli_stmt_bind_param($stmt_kelas, "i", $tingkat);
    mysqli_stmt_execute($stmt_kelas);
    $result_kelas = mysqli_stmt_get_result($stmt_kelas);
    
    while ($row = mysqli_fetch_assoc($result_kelas)) {
        $kelas_ids[] = (int)$row['id'];
    }
    mysqli_stmt_close($stmt_kelas);
    
    if (empty($kelas_ids)) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Tidak ada kelas di tingkat $tingkat"
        ]);
        mysqli_close($conn);
        exit();
    }
} else {
    $kelas_ids[] = $kelas_id;
}

// Query untuk mengambil jadwal dari semua kelas di tingkat tersebut
$placeholders = implode(',', array_fill(0, count($kelas_ids), '?'));
$query = "SELECT jk.id, jk.kelas_id, k.nama_kelas, k.tingkat, jk.hari, 
                 TIME_FORMAT(jk.jam_masuk, '%H:%i') as jam_masuk, 
                 TIME_FORMAT(jk.jam_pulang, '%H:%i') as jam_pulang,
                 jk.is_holiday,
                 jk.created_at, jk.updated_at
          FROM jadwal_kelas jk
          LEFT JOIN kelas k ON jk.kelas_id = k.id
          WHERE jk.kelas_id IN ($placeholders)
          ORDER BY jk.kelas_id, FIELD(jk.hari, 'senin','selasa','rabu','kamis','jumat','sabtu')";

$stmt = mysqli_prepare($conn, $query);

// Bind parameter dinamis
$types = str_repeat('i', count($kelas_ids));
mysqli_stmt_bind_param($stmt, $types, ...$kelas_ids);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengambil data jadwal: " . mysqli_error($conn)
    ]);
    mysqli_stmt_close($stmt);
    mysqli_close($conn);
    exit();
}

// Format data jadwal berdasarkan hari
$schedules = [];
while ($row = mysqli_fetch_assoc($result)) {
    $hari = $row['hari'];
    $kelasId = (int)$row['kelas_id'];
    
    if (!isset($schedules[$kelasId])) {
        $schedules[$kelasId] = [
            'kelas_id' => $kelasId,
            'nama_kelas' => $row['nama_kelas'],
            'tingkat' => (int)$row['tingkat'],
            'jadwal' => []
        ];
    }
    
    $schedules[$kelasId]['jadwal'][$hari] = [
        'id' => (int)$row['id'],
        'hari' => $hari,
        'jam_masuk' => $row['jam_masuk'],
        'jam_pulang' => $row['jam_pulang'],
        'is_holiday' => (bool)$row['is_holiday']
    ];
}

mysqli_stmt_close($stmt);

// Response sukses
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Data jadwal berhasil diambil",
    "tingkat" => $tingkat,
    "total_kelas" => count($schedules),
    "data" => array_values($schedules)
]);

// Tutup koneksi
mysqli_close($conn);
?>
