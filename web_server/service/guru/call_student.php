<?php
/**
 * Call Student for Pickup - Guru Piket
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Endpoint for teacher to call a student for pickup
 */

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method tidak diizinkan. Gunakan POST.'
    ]);
    exit();
}

require_once '../config/koneksi.php';

// Get POST data
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Data tidak valid.'
    ]);
    exit();
}

$siswa_id = isset($data['siswa_id']) ? (int)$data['siswa_id'] : 0;
$called_by = isset($data['called_by']) ? trim($data['called_by']) : 'Guru';
$penjemput = isset($data['penjemput']) ? trim($data['penjemput']) : 'guru';
$catatan = isset($data['catatan']) ? trim($data['catatan']) : null;

if ($siswa_id <= 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ID siswa tidak valid.'
    ]);
    exit();
}

try {
    // Check if student exists
    $check_siswa = mysqli_prepare($conn, "SELECT id, nama FROM siswa WHERE id = ?");
    mysqli_stmt_bind_param($check_siswa, "i", $siswa_id);
    mysqli_stmt_execute($check_siswa);
    $siswa_result = mysqli_stmt_get_result($check_siswa);
    
    if (mysqli_num_rows($siswa_result) === 0) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Siswa tidak ditemukan.'
        ]);
        mysqli_stmt_close($check_siswa);
        mysqli_close($conn);
        exit();
    }
    
    $siswa = mysqli_fetch_assoc($siswa_result);
    mysqli_stmt_close($check_siswa);
    
    // Get next queue number for today
    $queue_query = mysqli_query($conn, "
        SELECT COALESCE(MAX(nomor_antrian), 0) + 1 as next_queue 
        FROM permintaan_jemput 
        WHERE DATE(waktu_request) = CURDATE()
    ");
    $queue_row = mysqli_fetch_assoc($queue_query);
    $nomor_antrian = (int)$queue_row['next_queue'];
    
    // Get cooldown minutes from settings (default 10 if not set)
    $cooldown_query = "SELECT value FROM pengaturan_aplikasi WHERE key_name = 'cooldown_minutes' LIMIT 1";
    $cooldown_result = mysqli_query($conn, $cooldown_query);
    $cooldown_minutes = 10; // default
    if ($cooldown_result && mysqli_num_rows($cooldown_result) > 0) {
        $cooldown_row = mysqli_fetch_assoc($cooldown_result);
        $cooldown_minutes = intval($cooldown_row['value']);
    }
    
    // For guru-initiated requests, we need a valid user_id since the column is NOT NULL
    // Get the first available guru user_id to use as the requester
    $guru_user_query = mysqli_query($conn, "SELECT id FROM users WHERE role = 'guru' LIMIT 1");
    $guru_user_id = 1; // fallback default
    if ($guru_user_query && mysqli_num_rows($guru_user_query) > 0) {
        $guru_row = mysqli_fetch_assoc($guru_user_query);
        $guru_user_id = (int)$guru_row['id'];
    }
    
    // Insert pickup request - using permintaan_jemput table
    // Note: For guru-initiated requests, user_id is set to a valid guru's user_id
    // penjemput uses the original selection (ayah/ibu/ojek/lainnya)
    $insert_query = "
        INSERT INTO permintaan_jemput 
        (siswa_id, user_id, penjemput, penjemput_detail, estimasi_waktu, status, nomor_antrian, waktu_request, cooldown_minutes_used) 
        VALUES (?, ?, ?, ?, 'tiba', 'menunggu', ?, NOW(), ?)
    ";
    $stmt = mysqli_prepare($conn, $insert_query);
    
    if (!$stmt) {
        throw new Exception("Prepare error: " . mysqli_error($conn));
    }
    
    // penjemput_detail contains additional info (ojek type or other person's name)
    $penjemput_detail = $catatan;
    
    mysqli_stmt_bind_param($stmt, "iissii", $siswa_id, $guru_user_id, $penjemput, $penjemput_detail, $nomor_antrian, $cooldown_minutes);
    
    if (mysqli_stmt_execute($stmt)) {
        $request_id = mysqli_insert_id($conn);
        
        // Update siswa last_pickup_request
        $update_siswa = "UPDATE siswa SET last_pickup_request = NOW() WHERE id = $siswa_id";
        mysqli_query($conn, $update_siswa);
        
        echo json_encode([
            'success' => true,
            'message' => "Siswa {$siswa['nama']} berhasil dipanggil!",
            'data' => [
                'request_id' => $request_id,
                'nomor_antrian' => $nomor_antrian,
                'siswa_nama' => $siswa['nama'],
                'status' => 'menunggu'
            ]
        ]);
    } else {
        throw new Exception("Execute error: " . mysqli_error($conn));
    }
    
    mysqli_stmt_close($stmt);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Gagal memanggil siswa: ' . $e->getMessage()
    ]);
}

mysqli_close($conn);
?>
