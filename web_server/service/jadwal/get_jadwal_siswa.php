<?php
/**
 * Get Jadwal Siswa - SDIA 28 Sistem Penjemputan
 * File: service/jadwal/get_jadwal_siswa.php
 * 
 * Endpoint untuk mengambil jadwal berdasarkan kelas_id (untuk Flutter app siswa)
 * Method: GET
 * Parameter: kelas_id (required)
 * 
 * Response format:
 * {
 *   "success": true,
 *   "message": "Jadwal berhasil diambil",
 *   "data": {
 *     "kelas_id": 5,
 *     "nama_kelas": "3A",
 *     "tingkat": 3,
 *     "jadwal": {
 *       "senin": { "id": 1, "hari": "senin", "jam_masuk": "07:00", "jam_pulang": "12:30", "is_holiday": false },
 *       ...
 *     }
 *   }
 * }
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

// Ambil parameter kelas_id
$kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : null;

// Validasi parameter
if (!$kelas_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter 'kelas_id' diperlukan."
    ]);
    mysqli_close($conn);
    exit();
}

// Validasi kelas_id ada di database
$check_kelas = mysqli_prepare($conn, "SELECT id, nama_kelas, tingkat FROM kelas WHERE id = ?");
mysqli_stmt_bind_param($check_kelas, "i", $kelas_id);
mysqli_stmt_execute($check_kelas);
$result_kelas = mysqli_stmt_get_result($check_kelas);
$kelas_data = mysqli_fetch_assoc($result_kelas);

if (!$kelas_data) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Kelas dengan ID $kelas_id tidak ditemukan"
    ]);
    mysqli_stmt_close($check_kelas);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($check_kelas);

// Query untuk mengambil jadwal kelas
$query = "SELECT jk.id, jk.hari, 
                 TIME_FORMAT(jk.jam_masuk, '%H:%i') as jam_masuk, 
                 TIME_FORMAT(jk.jam_pulang, '%H:%i') as jam_pulang,
                 jk.is_holiday
          FROM jadwal_kelas jk
          WHERE jk.kelas_id = ?
          ORDER BY FIELD(jk.hari, 'senin','selasa','rabu','kamis','jumat')";

$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, "i", $kelas_id);
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

// Format data jadwal
$jadwal = [];
while ($row = mysqli_fetch_assoc($result)) {
    $hari = $row['hari'];
    $jadwal[$hari] = [
        'id' => (int)$row['id'],
        'hari' => $hari,
        'jam_masuk' => $row['jam_masuk'],
        'jam_pulang' => $row['jam_pulang'],
        'is_holiday' => (bool)$row['is_holiday']
    ];
}

mysqli_stmt_close($stmt);

// Jika tidak ada jadwal di database, buat default berdasarkan tingkat
if (empty($jadwal)) {
    $default_exit_times = [
        1 => '11:30',
        2 => '12:00',
        3 => '12:30',
        4 => '13:00',
        5 => '13:30',
        6 => '14:00'
    ];
    
    $tingkat = (int)$kelas_data['tingkat'];
    $default_exit = $default_exit_times[$tingkat] ?? '14:00';
    
    $days = ['senin', 'selasa', 'rabu', 'kamis', 'jumat'];
    foreach ($days as $day) {
        $jadwal[$day] = [
            'id' => null,
            'hari' => $day,
            'jam_masuk' => '07:00',
            'jam_pulang' => $default_exit,
            'is_holiday' => false
        ];
    }
}

// Response sukses
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Jadwal berhasil diambil",
    "data" => [
        "kelas_id" => (int)$kelas_data['id'],
        "nama_kelas" => $kelas_data['nama_kelas'],
        "tingkat" => (int)$kelas_data['tingkat'],
        "jadwal" => $jadwal
    ]
]);

// Tutup koneksi
mysqli_close($conn);
?>
