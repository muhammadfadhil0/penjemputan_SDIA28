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

date_default_timezone_set('Asia/Jakarta');

// Include database connection
require_once '../config/koneksi.php';
require_once '../lib/emergency.php';

$emergency_status = get_emergency_status($conn);

// Get cooldown minutes from settings (default 10 if not set)
$cooldown_query = "SELECT value FROM pengaturan_aplikasi WHERE key_name = 'cooldown_minutes' LIMIT 1";
$cooldown_result = mysqli_query($conn, $cooldown_query);
$cooldown_minutes = 10; // default
if ($cooldown_result && mysqli_num_rows($cooldown_result) > 0) {
    $cooldown_row = mysqli_fetch_assoc($cooldown_result);
    $cooldown_minutes = intval($cooldown_row['value']);
}
$cooldown_seconds = $cooldown_minutes * 60;

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
            pj.penjemput,
            pj.cooldown_minutes_used
          FROM permintaan_jemput pj
          WHERE pj.siswa_id = $siswa_id
          AND DATE(pj.waktu_request) = '$today'
          AND pj.status IN ('menunggu', 'dipanggil')
          ORDER BY pj.id DESC
          LIMIT 1";

$result = mysqli_query($conn, $query);

if (mysqli_num_rows($result) > 0) {
    $row = mysqli_fetch_assoc($result);
    
    // Use the cooldown value stored in the request (for consistency during countdown)
    // Fall back to global setting if not set
    $request_cooldown_minutes = isset($row['cooldown_minutes_used']) && $row['cooldown_minutes_used'] 
        ? intval($row['cooldown_minutes_used']) 
        : $cooldown_minutes;
    $request_cooldown_seconds = $request_cooldown_minutes * 60;
    
    // Calculate cooldown_remaining_seconds for 'dipanggil' status
    $cooldown_remaining = 0;
    $is_cooldown_expired = false;
    
    if ($row['status'] == 'dipanggil' && $row['waktu_dipanggil']) {
        $waktu_dipanggil = strtotime($row['waktu_dipanggil']);
        $cooldown_ends = $waktu_dipanggil + $request_cooldown_seconds;
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
            'status' => null,
            'emergency_mode' => $emergency_status
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
            'in_cooldown' => $cooldown_remaining > 0,
            'emergency_mode' => $emergency_status
        ]);
    }
} else {
    // Check if there was a recent 'dijemput' status (within cooldown period)
    // We need to check against the MAX possible cooldown (60 min) first, then use stored value
    $max_cooldown_ago = date('Y-m-d H:i:s', strtotime("-60 minutes"));
    
    $cooldown_query = "SELECT 
                        pj.id,
                        pj.waktu_dijemput,
                        pj.cooldown_minutes_used
                       FROM permintaan_jemput pj
                       WHERE pj.siswa_id = $siswa_id
                       AND DATE(pj.waktu_request) = '$today'
                       AND pj.status = 'dijemput'
                       AND pj.waktu_dijemput >= '$max_cooldown_ago'
                       ORDER BY pj.id DESC
                       LIMIT 1";
    
    $cooldown_result = mysqli_query($conn, $cooldown_query);
    
    if (mysqli_num_rows($cooldown_result) > 0) {
        $cooldown_row = mysqli_fetch_assoc($cooldown_result);
        
        // Use the cooldown value from the request (not the global setting)
        $dijemput_cooldown_minutes = isset($cooldown_row['cooldown_minutes_used']) && $cooldown_row['cooldown_minutes_used']
            ? intval($cooldown_row['cooldown_minutes_used'])
            : $cooldown_minutes;
        $dijemput_cooldown_seconds = $dijemput_cooldown_minutes * 60;
        
        $waktu_dijemput = strtotime($cooldown_row['waktu_dijemput']);
        $cooldown_ends = $waktu_dijemput + $dijemput_cooldown_seconds;
        $remaining_seconds = $cooldown_ends - time();
        
        // Only show cooldown if there's still time remaining
        if ($remaining_seconds > 0) {
            echo json_encode([
                'success' => true,
                'has_active_request' => false,
                'in_cooldown' => true,
                'cooldown_remaining_seconds' => max(0, $remaining_seconds),
                'waktu_dijemput' => $cooldown_row['waktu_dijemput'],
                'emergency_mode' => $emergency_status
            ]);
        } else {
            // Cooldown expired
            echo json_encode([
                'success' => true,
                'has_active_request' => false,
                'in_cooldown' => false,
                'status' => null,
                'emergency_mode' => $emergency_status
            ]);
        }
    } else {
        echo json_encode([
            'success' => true,
            'has_active_request' => false,
            'in_cooldown' => false,
            'status' => null,
            'emergency_mode' => $emergency_status
        ]);
    }
}

mysqli_close($conn);
?>
