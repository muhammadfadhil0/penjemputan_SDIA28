<?php
/**
 * API Endpoint: Ambil Antrean Penjemputan per Kelas
 * 
 * Mengambil daftar antrean penjemputan hari ini untuk kelas tertentu.
 * Digunakan oleh halaman kelas.html (class_view)
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

date_default_timezone_set('Asia/Jakarta');

// Include database connection
require_once '../config/koneksi.php';
require_once '../lib/emergency.php';

$emergency_status = get_emergency_status($conn);

// Get kelas_id parameter
$kelas_id = isset($_GET['kelas_id']) ? intval($_GET['kelas_id']) : 0;

if ($kelas_id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Parameter kelas_id diperlukan'
    ]);
    exit();
}

// Get today's date
$today = date('Y-m-d');

// Get queue with status 'menunggu' (waiting) - filtered by kelas_id
$queue_query = "SELECT 
                    pj.id,
                    pj.nomor_antrian,
                    s.nama as nama_siswa,
                    s.nama_panggilan,
                    s.foto_url,
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
                AND s.kelas_id = $kelas_id
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
        'foto_url' => $row['foto_url'],
        'nama_kelas' => 'Kelas ' . $row['nama_kelas'],
        'penjemput' => $penjemput_display,
        'penjemput_raw' => $row['penjemput'],
        'estimasi_waktu' => $row['estimasi_waktu'],
        'waktu_estimasi' => $row['waktu_estimasi'],
        'status' => $row['status'],
        'waktu_request' => $row['waktu_request']
    ];
}

// Get stats for today - filtered by kelas_id
$stats_query = "SELECT 
                    SUM(CASE WHEN pj.status = 'menunggu' THEN 1 ELSE 0 END) as waiting,
                    SUM(CASE WHEN pj.status = 'dipanggil' THEN 1 ELSE 0 END) as called,
                    SUM(CASE WHEN pj.status = 'dijemput' THEN 1 ELSE 0 END) as completed,
                    COUNT(*) as total
                FROM permintaan_jemput pj
                JOIN siswa s ON pj.siswa_id = s.id
                WHERE DATE(pj.waktu_request) = '$today'
                AND s.kelas_id = $kelas_id";

$stats_result = mysqli_query($conn, $stats_query);
$stats_row = mysqli_fetch_assoc($stats_result);

$stats = [
    'waiting' => intval($stats_row['waiting'] ?? 0),
    'called' => intval($stats_row['called'] ?? 0) + intval($stats_row['completed'] ?? 0),
    'total' => intval($stats_row['total'] ?? 0)
];

// Get all students from this class (for dropdown)
$students_query = "SELECT s.id, s.nama, s.nama_panggilan, s.foto_url, k.nama_kelas 
                   FROM siswa s 
                   JOIN kelas k ON s.kelas_id = k.id 
                   WHERE s.kelas_id = $kelas_id
                   ORDER BY s.nama";
$students_result = mysqli_query($conn, $students_query);

$students = [];
while ($row = mysqli_fetch_assoc($students_result)) {
    $students[] = [
        'id' => intval($row['id']),
        'name' => $row['nama'],
        'nickname' => $row['nama_panggilan'],
        'foto_url' => $row['foto_url'],
        'class' => 'Kelas ' . $row['nama_kelas']
    ];
}

echo json_encode([
    'success' => true,
    'queue' => $queue,
    'stats' => $stats,
    'students' => $students,
    'kelas_id' => $kelas_id,
    'timestamp' => date('Y-m-d H:i:s'),
    'emergency_mode' => $emergency_status
]);

mysqli_close($conn);
?>
