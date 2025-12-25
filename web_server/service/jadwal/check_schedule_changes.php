<?php
/**
 * Check Schedule Changes - SDIA 28 Sistem Penjemputan
 * File: service/jadwal/check_schedule_changes.php
 * 
 * Endpoint untuk mengecek apakah ada perubahan jadwal untuk kelas tertentu
 * Method: GET
 * Parameters:
 *   - kelas_id: ID kelas yang ingin dicek
 *   - last_seen: Timestamp terakhir yang diketahui client (format: Y-m-d H:i:s)
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
$kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : 0;
$last_seen = isset($_GET['last_seen']) ? trim($_GET['last_seen']) : null;

// Validasi kelas_id
if ($kelas_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter kelas_id diperlukan dan harus berupa angka positif"
    ]);
    mysqli_close($conn);
    exit();
}

// Validasi kelas_id ada di database
$check_kelas = mysqli_prepare($conn, "SELECT id, nama_kelas FROM kelas WHERE id = ?");
mysqli_stmt_bind_param($check_kelas, "i", $kelas_id);
mysqli_stmt_execute($check_kelas);
$result_kelas = mysqli_stmt_get_result($check_kelas);

if (mysqli_num_rows($result_kelas) === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Kelas dengan ID $kelas_id tidak ditemukan"
    ]);
    mysqli_stmt_close($check_kelas);
    mysqli_close($conn);
    exit();
}
$kelas_data = mysqli_fetch_assoc($result_kelas);
mysqli_stmt_close($check_kelas);

// Ambil jadwal terbaru beserta info updated_at
$query = "SELECT MAX(updated_at) as latest_update FROM jadwal_kelas WHERE kelas_id = ?";
$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, "i", $kelas_id);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
$row = mysqli_fetch_assoc($result);
mysqli_stmt_close($stmt);

$latest_update = $row['latest_update'];
$has_changes = false;

// Cek apakah ada perubahan
if ($latest_update !== null && $last_seen !== null) {
    // Bandingkan timestamp
    $latest_timestamp = strtotime($latest_update);
    $last_seen_timestamp = strtotime($last_seen);
    
    if ($latest_timestamp > $last_seen_timestamp) {
        $has_changes = true;
    }
} elseif ($latest_update !== null && $last_seen === null) {
    // Jika client belum punya last_seen, berarti ini pertama kali - tidak dianggap ada perubahan
    $has_changes = false;
}

// Ambil jadwal lengkap untuk hari ini (jika ada perubahan)
$today_schedule = null;
if ($has_changes) {
    // Tentukan hari ini dalam format yang sesuai dengan enum database
    $hari_mapping = [
        1 => 'senin',
        2 => 'selasa',
        3 => 'rabu',
        4 => 'kamis',
        5 => 'jumat',
        6 => 'sabtu',
    ];
    $today_index = date('N'); // 1 (Senin) sampai 7 (Minggu)
    $today_hari = isset($hari_mapping[$today_index]) ? $hari_mapping[$today_index] : null;
    
    if ($today_hari !== null) {
        $query_today = "SELECT hari, jam_masuk, jam_pulang, is_holiday, updated_at 
                        FROM jadwal_kelas 
                        WHERE kelas_id = ? AND hari = ?";
        $stmt_today = mysqli_prepare($conn, $query_today);
        mysqli_stmt_bind_param($stmt_today, "is", $kelas_id, $today_hari);
        mysqli_stmt_execute($stmt_today);
        $result_today = mysqli_stmt_get_result($stmt_today);
        
        if ($row_today = mysqli_fetch_assoc($result_today)) {
            $today_schedule = [
                'hari' => $row_today['hari'],
                'jam_masuk' => $row_today['jam_masuk'],
                'jam_pulang' => $row_today['jam_pulang'],
                'is_holiday' => (bool)$row_today['is_holiday'],
                'updated_at' => $row_today['updated_at']
            ];
        }
        mysqli_stmt_close($stmt_today);
    }
}

// Response
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => $has_changes ? "Ada perubahan jadwal" : "Tidak ada perubahan jadwal",
    "data" => [
        "kelas_id" => $kelas_id,
        "kelas_nama" => $kelas_data['nama_kelas'],
        "has_changes" => $has_changes,
        "latest_update" => $latest_update,
        "today_schedule" => $today_schedule
    ]
]);

// Tutup koneksi
mysqli_close($conn);
?>
