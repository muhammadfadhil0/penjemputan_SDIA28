<?php
/**
 * API Endpoint: Tambah Permintaan Jemput
 * 
 * Menerima request POST dari Flutter app untuk menambah permintaan jemput ke database.
 * Request akan masuk ke antrean dan bisa dilihat di web dashboard.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once '../config/koneksi.php';

// Get cooldown minutes from settings (default 10 if not set)
$cooldown_query_setting = "SELECT value FROM pengaturan_aplikasi WHERE key_name = 'cooldown_minutes' LIMIT 1";
$cooldown_result_setting = mysqli_query($conn, $cooldown_query_setting);
$cooldown_minutes = 10; // default
if ($cooldown_result_setting && mysqli_num_rows($cooldown_result_setting) > 0) {
    $cooldown_row_setting = mysqli_fetch_assoc($cooldown_result_setting);
    $cooldown_minutes = intval($cooldown_row_setting['value']);
}
$cooldown_seconds = $cooldown_minutes * 60;

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use POST.'
    ]);
    exit();
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
if (!isset($input['siswa_id']) || !isset($input['penjemput']) || !isset($input['estimasi_waktu'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Data tidak lengkap. Diperlukan: siswa_id, penjemput, estimasi_waktu'
    ]);
    exit();
}

$siswa_id = intval($input['siswa_id']);
$penjemput = mysqli_real_escape_string($conn, $input['penjemput']);
$penjemput_detail = isset($input['penjemput_detail']) ? mysqli_real_escape_string($conn, $input['penjemput_detail']) : null;
$estimasi_waktu = mysqli_real_escape_string($conn, $input['estimasi_waktu']);
$waktu_estimasi = isset($input['waktu_estimasi']) ? mysqli_real_escape_string($conn, $input['waktu_estimasi']) : null;

// Validate siswa exists and get info
$siswa_query = "SELECT s.id, s.nama, s.last_pickup_request, k.nama_kelas 
                FROM siswa s 
                JOIN kelas k ON s.kelas_id = k.id 
                WHERE s.id = $siswa_id";
$siswa_result = mysqli_query($conn, $siswa_query);

if (mysqli_num_rows($siswa_result) == 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Siswa tidak ditemukan'
    ]);
    exit();
}

$siswa = mysqli_fetch_assoc($siswa_result);

// NOTE: Allow new request if previous 'dipanggil' status cooldown has expired
$today = date('Y-m-d');

$existing_query = "SELECT id, status, waktu_dipanggil, cooldown_minutes_used FROM permintaan_jemput 
                   WHERE siswa_id = $siswa_id 
                   AND DATE(waktu_request) = '$today' 
                   AND status IN ('menunggu', 'dipanggil')
                   ORDER BY id DESC
                   LIMIT 1";
$existing_result = mysqli_query($conn, $existing_query);

if (mysqli_num_rows($existing_result) > 0) {
    $existing = mysqli_fetch_assoc($existing_result);
    
    // If status is 'dipanggil' and cooldown has expired, allow new request
    if ($existing['status'] == 'dipanggil' && $existing['waktu_dipanggil']) {
        // Use the cooldown stored in the request for consistency
        $existing_cooldown_minutes = isset($existing['cooldown_minutes_used']) && $existing['cooldown_minutes_used']
            ? intval($existing['cooldown_minutes_used'])
            : $cooldown_minutes;
        $existing_cooldown_seconds = $existing_cooldown_minutes * 60;
        
        $waktu_dipanggil = strtotime($existing['waktu_dipanggil']);
        $cooldown_ends = $waktu_dipanggil + $existing_cooldown_seconds;
        
        if (time() >= $cooldown_ends) {
            // Cooldown expired, allow new request - update old request to 'dibatalkan' first
            $update_old = "UPDATE permintaan_jemput SET status = 'dibatalkan' WHERE id = " . $existing['id'];
            mysqli_query($conn, $update_old);
        } else {
            // Still in cooldown
            $remaining = $cooldown_ends - time();
            $minutes = floor($remaining / 60);
            $seconds = $remaining % 60;
            echo json_encode([
                'success' => false,
                'message' => "Tunggu " . sprintf("%d:%02d", $minutes, $seconds) . " lagi sebelum dapat memanggil kembali"
            ]);
            exit();
        }
    } else if ($existing['status'] == 'menunggu') {
        // Still waiting in queue
        echo json_encode([
            'success' => false,
            'message' => 'Sudah ada permintaan jemput yang aktif untuk hari ini'
        ]);
        exit();
    }
}

// Get next queue number for today
$queue_query = "SELECT COALESCE(MAX(nomor_antrian), 0) + 1 as next_queue 
                FROM permintaan_jemput 
                WHERE DATE(waktu_request) = '$today'";
$queue_result = mysqli_query($conn, $queue_query);
$next_queue = mysqli_fetch_assoc($queue_result)['next_queue'];

// We don't have user_id for siswa login, so we'll use siswa_id as user_id reference
// This is a simplified approach - in production you might want a proper user table join
$user_id = $siswa_id; // Using siswa_id as a placeholder

// Prepare waktu_estimasi for SQL
$waktu_estimasi_sql = $waktu_estimasi ? "'$waktu_estimasi'" : "NULL";
$penjemput_detail_sql = $penjemput_detail ? "'$penjemput_detail'" : "NULL";

// Insert pickup request (include cooldown_minutes_used so countdown is fixed per-request)
$insert_query = "INSERT INTO permintaan_jemput 
                 (siswa_id, user_id, penjemput, penjemput_detail, estimasi_waktu, waktu_estimasi, 
                  status, nomor_antrian, waktu_request, cooldown_minutes_used) 
                 VALUES 
                 ($siswa_id, $user_id, '$penjemput', $penjemput_detail_sql, '$estimasi_waktu', 
                  $waktu_estimasi_sql, 'menunggu', $next_queue, NOW(), $cooldown_minutes)";

if (mysqli_query($conn, $insert_query)) {
    $request_id = mysqli_insert_id($conn);
    
    // Update siswa last_pickup_request
    $update_siswa = "UPDATE siswa SET last_pickup_request = NOW() WHERE id = $siswa_id";
    mysqli_query($conn, $update_siswa);
    
    echo json_encode([
        'success' => true,
        'message' => 'Permintaan jemput berhasil dikirim!',
        'data' => [
            'request_id' => $request_id,
            'nomor_antrian' => intval($next_queue),
            'nama_siswa' => $siswa['nama'],
            'kelas' => $siswa['nama_kelas']
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan permintaan: ' . mysqli_error($conn)
    ]);
}

mysqli_close($conn);
?>
