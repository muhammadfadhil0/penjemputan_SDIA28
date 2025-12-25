<?php
/**
 * API Endpoint: Ambil Antrean Penjemputan
 * 
 * Mengambil daftar antrean penjemputan hari ini untuk ditampilkan di web dashboard.
 * Mendukung polling (auto-refresh setiap beberapa detik).
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once '../config/koneksi.php';

// Get today's date
$today = date('Y-m-d');

// Get queue with status 'menunggu' (waiting) - ordered by queue number
$queue_query = "SELECT 
                    pj.id,
                    pj.nomor_antrian,
                    s.nama as nama_siswa,
                    s.nama_panggilan,
                    k.nama_kelas,
                    pj.penjemput,
                    pj.penjemput_detail,
                    pj.estimasi_waktu,
                    pj.waktu_estimasi,
                    pj.status,
                    pj.waktu_request
                FROM permintaan_jemput pj
                JOIN siswa s ON pj.siswa_id = s.id
                JOIN kelas k ON s.kelas_id = k.id
                WHERE DATE(pj.waktu_request) = '$today'
                AND pj.status = 'menunggu'
                ORDER BY pj.nomor_antrian ASC";

$queue_result = mysqli_query($conn, $queue_query);

$queue = [];
while ($row = mysqli_fetch_assoc($queue_result)) {
    // Format penjemput display
    $penjemput_display = ucfirst($row['penjemput']);
    if ($row['penjemput_detail']) {
        $penjemput_display .= ' (' . $row['penjemput_detail'] . ')';
    }
    
    $queue[] = [
        'id' => intval($row['id']),
        'nomor_antrian' => intval($row['nomor_antrian']),
        'nama_siswa' => $row['nama_siswa'],
        'nama_panggilan' => $row['nama_panggilan'],
        'nama_kelas' => 'Kelas ' . $row['nama_kelas'],
        'penjemput' => $penjemput_display,
        'penjemput_raw' => $row['penjemput'],
        'estimasi_waktu' => $row['estimasi_waktu'],
        'waktu_estimasi' => $row['waktu_estimasi'],
        'status' => $row['status'],
        'waktu_request' => $row['waktu_request']
    ];
}

// Get stats for today
$stats_query = "SELECT 
                    SUM(CASE WHEN status = 'menunggu' THEN 1 ELSE 0 END) as waiting,
                    SUM(CASE WHEN status = 'dipanggil' THEN 1 ELSE 0 END) as called,
                    SUM(CASE WHEN status = 'dijemput' THEN 1 ELSE 0 END) as completed,
                    COUNT(*) as total
                FROM permintaan_jemput
                WHERE DATE(waktu_request) = '$today'";

$stats_result = mysqli_query($conn, $stats_query);
$stats_row = mysqli_fetch_assoc($stats_result);

$stats = [
    'waiting' => intval($stats_row['waiting'] ?? 0),
    'called' => intval($stats_row['called'] ?? 0) + intval($stats_row['completed'] ?? 0),
    'total' => intval($stats_row['total'] ?? 0)
];

// Get all students for dropdown (to add manually from web dashboard)
$students_query = "SELECT s.id, s.nama, s.nama_panggilan, k.nama_kelas 
                   FROM siswa s 
                   JOIN kelas k ON s.kelas_id = k.id 
                   ORDER BY k.nama_kelas, s.nama";
$students_result = mysqli_query($conn, $students_query);

$students = [];
while ($row = mysqli_fetch_assoc($students_result)) {
    $students[] = [
        'id' => intval($row['id']),
        'name' => $row['nama'],
        'nickname' => $row['nama_panggilan'],
        'class' => 'Kelas ' . $row['nama_kelas']
    ];
}

echo json_encode([
    'success' => true,
    'queue' => $queue,
    'stats' => $stats,
    'students' => $students,
    'timestamp' => date('Y-m-d H:i:s')
]);

mysqli_close($conn);
?>
