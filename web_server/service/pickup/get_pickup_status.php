<?php
/**
 * API Endpoint: Cek Status Penjemputan Siswa
 * 
 * Mengecek apakah siswa memiliki permintaan jemput yang aktif hari ini
 * dan statusnya (menunggu, dipanggil, atau sudah selesai).
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once '../config/koneksi.php';

// Get siswa_id from query or POST
$siswa_id = null;
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $siswa_id = isset($_GET['siswa_id']) ? intval($_GET['siswa_id']) : null;
} else {
    $input = json_decode(file_get_contents('php://input'), true);
    $siswa_id = isset($input['siswa_id']) ? intval($input['siswa_id']) : null;
}

if (!$siswa_id) {
    echo json_encode([
        'success' => false,
        'message' => 'siswa_id diperlukan'
    ]);
    exit();
}

// Get today's date
$today = date('Y-m-d');

// Check for active pickup request today
$query = "SELECT 
            pj.id,
            pj.status,
            pj.nomor_antrian,
            pj.waktu_request,
            pj.waktu_dipanggil,
            pj.waktu_dijemput,
            pj.penjemput
          FROM permintaan_jemput pj
          WHERE pj.siswa_id = $siswa_id
          AND DATE(pj.waktu_request) = '$today'
          AND pj.status IN ('menunggu', 'dipanggil')
          ORDER BY pj.id DESC
          LIMIT 1";

$result = mysqli_query($conn, $query);

if (mysqli_num_rows($result) > 0) {
    $row = mysqli_fetch_assoc($result);
    
    // Calculate cooldown_remaining_seconds for 'dipanggil' status
    $cooldown_remaining = 0;
    $is_cooldown_expired = false;
    
    if ($row['status'] == 'dipanggil' && $row['waktu_dipanggil']) {
        $waktu_dipanggil = strtotime($row['waktu_dipanggil']);
        $cooldown_ends = $waktu_dipanggil + (10 * 60); // 10 minutes
        $cooldown_remaining = max(0, $cooldown_ends - time());
        
        // If cooldown expired (more than 10 minutes since called), treat as IDLE
        if ($cooldown_remaining <= 0) {
            $is_cooldown_expired = true;
        }
    }
    
    // If 'dipanggil' cooldown expired, return as IDLE so user can request again
    if ($is_cooldown_expired) {
        echo json_encode([
            'success' => true,
            'has_active_request' => false,
            'in_cooldown' => false,
            'status' => null
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'has_active_request' => true,
            'request_id' => intval($row['id']),
            'status' => $row['status'],
            'nomor_antrian' => intval($row['nomor_antrian']),
            'penjemput' => $row['penjemput'],
            'waktu_request' => $row['waktu_request'],
            'waktu_dipanggil' => $row['waktu_dipanggil'],
            'cooldown_remaining_seconds' => $cooldown_remaining,
            'in_cooldown' => $cooldown_remaining > 0
        ]);
    }
} else {
    // Check if there was a recent 'dijemput' status (within last 10 minutes)
    $ten_minutes_ago = date('Y-m-d H:i:s', strtotime('-10 minutes'));
    
    $cooldown_query = "SELECT 
                        pj.id,
                        pj.waktu_dijemput
                       FROM permintaan_jemput pj
                       WHERE pj.siswa_id = $siswa_id
                       AND DATE(pj.waktu_request) = '$today'
                       AND pj.status = 'dijemput'
                       AND pj.waktu_dijemput >= '$ten_minutes_ago'
                       ORDER BY pj.id DESC
                       LIMIT 1";
    
    $cooldown_result = mysqli_query($conn, $cooldown_query);
    
    if (mysqli_num_rows($cooldown_result) > 0) {
        $cooldown_row = mysqli_fetch_assoc($cooldown_result);
        $waktu_dijemput = strtotime($cooldown_row['waktu_dijemput']);
        $cooldown_ends = $waktu_dijemput + (10 * 60); // 10 minutes
        $remaining_seconds = $cooldown_ends - time();
        
        echo json_encode([
            'success' => true,
            'has_active_request' => false,
            'in_cooldown' => true,
            'cooldown_remaining_seconds' => max(0, $remaining_seconds),
            'waktu_dijemput' => $cooldown_row['waktu_dijemput']
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'has_active_request' => false,
            'in_cooldown' => false,
            'status' => null
        ]);
    }
}

mysqli_close($conn);
?>
