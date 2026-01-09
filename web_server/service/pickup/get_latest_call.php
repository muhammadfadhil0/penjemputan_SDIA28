<?php
/**
 * API Endpoint: Ambil Panggilan Terbaru
 * 
 * Mengambil data panggilan terbaru yang berstatus 'dipanggil'
 * untuk diputar TTS-nya di halaman kelas.
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

if ($emergency_status['active'] === true) {
    echo json_encode([
        'success' => true,
        'call' => null,
        'message' => 'Emergency mode aktif - pemanggilan dialihkan ke aplikasi kelas',
        'emergency_mode' => $emergency_status
    ]);
    exit();
}

// Get today's date
$today = date('Y-m-d');

// Get the latest call that has status 'dipanggil' (being called)
// This picks up the most recently called student
$query = "SELECT 
                pj.id,
                pj.nomor_antrian,
                s.nama as nama_siswa,
                s.nama_panggilan,
                s.foto_url,
                k.nama_kelas,
                pj.penjemput,
                pj.penjemput_detail,
                pj.status,
                pj.waktu_dipanggil,
                pj.waktu_request
            FROM permintaan_jemput pj
            JOIN siswa s ON pj.siswa_id = s.id
            JOIN kelas k ON s.kelas_id = k.id
            WHERE DATE(pj.waktu_request) = '$today'
            AND pj.status = 'dipanggil'
            ORDER BY pj.waktu_dipanggil DESC
            LIMIT 1";

$result = mysqli_query($conn, $query);

if ($result && mysqli_num_rows($result) > 0) {
    $row = mysqli_fetch_assoc($result);
    
    // Format penjemput display
    $penjemput_display = ucfirst($row['penjemput']);
    if ($row['penjemput_detail']) {
        $penjemput_display .= ' (' . $row['penjemput_detail'] . ')';
    }
    
    $call = [
        'id' => intval($row['id']),
        'nomor_antrian' => intval($row['nomor_antrian']),
        'nama_siswa' => $row['nama_panggilan'] ?: $row['nama_siswa'],
        'nama_lengkap' => $row['nama_siswa'],
        'foto_url' => $row['foto_url'],
        'nama_kelas' => 'Kelas ' . $row['nama_kelas'],
        'penjemput' => $penjemput_display,
        'penjemput_raw' => $row['penjemput'],
        'status' => $row['status'],
        'waktu_dipanggil' => $row['waktu_dipanggil'],
        'waktu_request' => $row['waktu_request']
    ];
    
    echo json_encode([
        'success' => true,
        'call' => $call,
        'message' => 'Latest call retrieved',
        'emergency_mode' => $emergency_status
    ]);
} else {
    // No active call
    echo json_encode([
        'success' => true,
        'call' => null,
        'message' => 'No active call',
        'emergency_mode' => $emergency_status
    ]);
}

mysqli_close($conn);
?>
