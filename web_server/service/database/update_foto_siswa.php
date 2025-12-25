<?php
/**
 * Update Foto Siswa URL - SDIA 28 Sistem Penjemputan
 * File: service/database/update_foto_siswa.php
 * 
 * Endpoint untuk mengupdate URL foto profil siswa (untuk avatar CDN)
 */

// Set header untuk response JSON dan CORS
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Hanya terima method POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST."
    ]);
    exit();
}

// Include file koneksi database
require_once '../config/koneksi.php';

// Ambil data dari request
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Jika data tidak dalam format JSON, coba ambil dari form data
if (!$data) {
    $data = [
        'siswa_id' => $_POST['siswa_id'] ?? '',
        'foto_url' => $_POST['foto_url'] ?? ''
    ];
}

// Validasi input
$siswa_id = (int) ($data['siswa_id'] ?? 0);
$foto_url = trim($data['foto_url'] ?? '');

if ($siswa_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "ID siswa tidak valid."
    ]);
    exit();
}

if (empty($foto_url)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "URL foto tidak boleh kosong."
    ]);
    exit();
}

// Validasi URL foto (harus dari CDN yang diizinkan)
$allowed_domains = [
    'api.dicebear.com',
    'ui-avatars.com',
    'soulhbc.com'
];

$url_host = parse_url($foto_url, PHP_URL_HOST);
$is_valid_domain = false;
foreach ($allowed_domains as $domain) {
    if ($url_host === $domain || strpos($url_host, $domain) !== false) {
        $is_valid_domain = true;
        break;
    }
}

if (!$is_valid_domain) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "URL foto harus dari sumber yang diizinkan."
    ]);
    exit();
}

// Cek apakah siswa ada
$check_siswa = mysqli_prepare($conn, "SELECT id, foto_url FROM siswa WHERE id = ?");
mysqli_stmt_bind_param($check_siswa, "i", $siswa_id);
mysqli_stmt_execute($check_siswa);
$siswa_result = mysqli_stmt_get_result($check_siswa);

if (mysqli_num_rows($siswa_result) === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Siswa tidak ditemukan."
    ]);
    mysqli_stmt_close($check_siswa);
    mysqli_close($conn);
    exit();
}

$siswa = mysqli_fetch_assoc($siswa_result);
$old_foto_url = $siswa['foto_url'];
mysqli_stmt_close($check_siswa);

// Hapus file foto lama jika bukan dari CDN (foto upload lokal)
if (!empty($old_foto_url) && strpos($old_foto_url, 'api.dicebear.com') === false && strpos($old_foto_url, 'ui-avatars.com') === false) {
    // Konversi URL ke path file
    $file_path = '../../' . str_replace('https://soulhbc.com/penjemputan/', '', $old_foto_url);
    if (file_exists($file_path)) {
        unlink($file_path);
    }
}

// Update database dengan URL baru
$update_query = "UPDATE siswa SET foto_url = ? WHERE id = ?";
$update_stmt = mysqli_prepare($conn, $update_query);
mysqli_stmt_bind_param($update_stmt, "si", $foto_url, $siswa_id);

if (mysqli_stmt_execute($update_stmt)) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Avatar profil berhasil diperbarui!",
        "data" => [
            "foto_url" => $foto_url
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal memperbarui foto di database."
    ]);
}

mysqli_stmt_close($update_stmt);
mysqli_close($conn);
?>
