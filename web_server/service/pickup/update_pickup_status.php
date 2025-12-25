<?php
/**
 * API Endpoint: Update Status Penjemputan
 * 
 * Mengupdate status permintaan jemput: dipanggil, dijemput, atau dibatalkan.
 * Digunakan oleh web dashboard saat memanggil atau menyelesaikan penjemputan.
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
if (!isset($input['request_id']) || !isset($input['status'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Data tidak lengkap. Diperlukan: request_id, status'
    ]);
    exit();
}

$request_id = intval($input['request_id']);
$new_status = mysqli_real_escape_string($conn, $input['status']);

// Validate status value
$valid_statuses = ['menunggu', 'dipanggil', 'dijemput', 'dibatalkan'];
if (!in_array($new_status, $valid_statuses)) {
    echo json_encode([
        'success' => false,
        'message' => 'Status tidak valid. Gunakan: menunggu, dipanggil, dijemput, dibatalkan'
    ]);
    exit();
}

// Check if request exists
$check_query = "SELECT pj.id, pj.siswa_id, pj.status, s.nama as nama_siswa 
                FROM permintaan_jemput pj 
                JOIN siswa s ON pj.siswa_id = s.id
                WHERE pj.id = $request_id";
$check_result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($check_result) == 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Permintaan jemput tidak ditemukan'
    ]);
    exit();
}

$request = mysqli_fetch_assoc($check_result);
$siswa_id = $request['siswa_id'];

// Build update query based on new status
$timestamp_field = '';
if ($new_status === 'dipanggil') {
    $timestamp_field = ", waktu_dipanggil = NOW()";
} elseif ($new_status === 'dijemput') {
    $timestamp_field = ", waktu_dijemput = NOW()";
}

// Update status
$update_query = "UPDATE permintaan_jemput 
                 SET status = '$new_status' $timestamp_field 
                 WHERE id = $request_id";

if (mysqli_query($conn, $update_query)) {
    // If status changed to 'dijemput', also update status_penjemputan_harian
    if ($new_status === 'dijemput') {
        $today = date('Y-m-d');
        
        // Check if record exists
        $check_daily = "SELECT id FROM status_penjemputan_harian 
                        WHERE siswa_id = $siswa_id AND tanggal = '$today'";
        $daily_result = mysqli_query($conn, $check_daily);
        
        // Get penjemput info
        $penjemput_query = "SELECT penjemput, penjemput_detail FROM permintaan_jemput WHERE id = $request_id";
        $penjemput_result = mysqli_query($conn, $penjemput_query);
        $penjemput_info = mysqli_fetch_assoc($penjemput_result);
        $penjemput = mysqli_real_escape_string($conn, $penjemput_info['penjemput']);
        
        if (mysqli_num_rows($daily_result) > 0) {
            // Update existing record
            $update_daily = "UPDATE status_penjemputan_harian 
                            SET sudah_dijemput = 1, waktu_dijemput = NOW(), penjemput = '$penjemput'
                            WHERE siswa_id = $siswa_id AND tanggal = '$today'";
            mysqli_query($conn, $update_daily);
        } else {
            // Insert new record
            $insert_daily = "INSERT INTO status_penjemputan_harian 
                            (siswa_id, tanggal, sudah_dijemput, waktu_dijemput, penjemput) 
                            VALUES ($siswa_id, '$today', 1, NOW(), '$penjemput')";
            mysqli_query($conn, $insert_daily);
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Status berhasil diupdate',
        'data' => [
            'request_id' => $request_id,
            'nama_siswa' => $request['nama_siswa'],
            'old_status' => $request['status'],
            'new_status' => $new_status
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengupdate status: ' . mysqli_error($conn)
    ]);
}

mysqli_close($conn);
?>
