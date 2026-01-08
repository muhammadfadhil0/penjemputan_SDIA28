<?php
/**
 * Backend Class View - Get Pickup History by Kelas
 * File: service/class_view/get_class_history.php
 * 
 * Endpoint untuk mengambil riwayat penjemputan berdasarkan kelas_id hari ini
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

// Set timezone ke WIB (Jakarta)
date_default_timezone_set('Asia/Jakarta');

// Ambil kelas_id dari parameter
$kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : 0;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;

// Parameter tanggal opsional (format: YYYY-MM-DD)
$tanggal = isset($_GET['tanggal']) ? $_GET['tanggal'] : null;

if ($kelas_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Parameter kelas_id diperlukan."
    ]);
    exit();
}

// Gunakan tanggal yang diberikan atau hari ini
if ($tanggal && preg_match('/^\d{4}-\d{2}-\d{2}$/', $tanggal)) {
    $today = $tanggal;
} else {
    $today = date('Y-m-d');
}

// Query riwayat penjemputan hari ini berdasarkan kelas
// ORDER BY waktu_dipanggil ASC untuk menghitung urutan panggilan per siswa
$query = "SELECT 
            pj.id,
            pj.siswa_id,
            pj.penjemput,
            pj.penjemput_detail,
            pj.status,
            pj.waktu_request,
            pj.waktu_dipanggil,
            pj.waktu_dijemput,
            s.nama AS nama_siswa,
            s.nama_panggilan
          FROM permintaan_jemput pj
          JOIN siswa s ON pj.siswa_id = s.id
          WHERE s.kelas_id = ? 
            AND DATE(pj.waktu_request) = ?
            AND pj.status IN ('dipanggil', 'dijemput')
          ORDER BY pj.waktu_dipanggil ASC, pj.waktu_request ASC";

$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, "is", $kelas_id, $today);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

// Hitung berapa kali setiap siswa sudah dipanggil
$siswaPickupCount = [];
$allHistory = [];

while ($row = mysqli_fetch_assoc($result)) {
    $siswaId = (int)$row['siswa_id'];
    
    // Increment counter untuk siswa ini
    if (!isset($siswaPickupCount[$siswaId])) {
        $siswaPickupCount[$siswaId] = 0;
    }
    $siswaPickupCount[$siswaId]++;
    
    // Format penjemput display
    $penjemputDisplay = ucfirst($row['penjemput']);
    if ($row['penjemput_detail']) {
        $penjemputDisplay .= ' (' . $row['penjemput_detail'] . ')';
    }
    
    // Format waktu
    $waktu = $row['waktu_dipanggil'] ?? $row['waktu_request'];
    $waktuFormatted = date('H:i', strtotime($waktu));
    
    // Format nama dengan urutan panggilan jika lebih dari 1
    $namaSiswa = $row['nama_panggilan'] ?? $row['nama_siswa'];
    $panggilanKe = $siswaPickupCount[$siswaId];
    
    // Mapping angka ke teks
    $ordinalLabels = [
        2 => 'Panggilan kedua',
        3 => 'Panggilan ketiga',
        4 => 'Panggilan keempat',
        5 => 'Panggilan kelima',
        6 => 'Panggilan keenam',
        7 => 'Panggilan ketujuh',
        8 => 'Panggilan kedelapan',
        9 => 'Panggilan kesembilan',
        10 => 'Panggilan kesepuluh'
    ];
    
    if ($panggilanKe > 1) {
        $label = isset($ordinalLabels[$panggilanKe]) ? $ordinalLabels[$panggilanKe] : "Panggilan ke-$panggilanKe";
        $namaSiswaDisplay = $namaSiswa . ' (' . $label . ')';
    } else {
        $namaSiswaDisplay = $namaSiswa;
    }
    
    $allHistory[] = [
        "id" => (int)$row['id'],
        "siswa_id" => $siswaId,
        "nama_siswa" => $namaSiswaDisplay,
        "nama_asli" => $namaSiswa,
        "nama_lengkap" => $row['nama_siswa'],
        "penjemput" => $penjemputDisplay,
        "penjemput_raw" => $row['penjemput'],
        "status" => $row['status'],
        "panggilan_ke" => $panggilanKe,
        "waktu" => $waktuFormatted,
        "waktu_full" => $waktu
    ];
}

mysqli_stmt_close($stmt);

// Reverse untuk menampilkan terbaru di atas, lalu limit
$history = array_reverse($allHistory);
$history = array_slice($history, 0, $limit);

// Response
http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Riwayat penjemputan berhasil diambil.",
    "tanggal" => $today,
    "count" => count($history),
    "data" => $history
]);

mysqli_close($conn);
?>
