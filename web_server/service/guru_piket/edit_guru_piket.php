<?php
/**
 * Edit Guru Piket - SDIA 28 Sistem Penjemputan
 */
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method tidak diizinkan."]);
    exit();
}

require_once '../config/koneksi.php';

$data = json_decode(file_get_contents("php://input"), true);
$id = (int)($data['id'] ?? 0);
$username = trim($data['username'] ?? '');
$password = trim($data['password'] ?? '');
$nama = trim($data['nama'] ?? '');
$no_telepon = trim($data['no_telepon'] ?? '');

if ($id <= 0 || empty($username) || empty($password) || empty($nama)) {
    echo json_encode(["success" => false, "message" => "Data tidak lengkap."]);
    exit();
}

// Check duplicate username (exclude current)
$check = mysqli_prepare($conn, "SELECT id FROM users WHERE username = ? AND id != ?");
mysqli_stmt_bind_param($check, "si", $username, $id);
mysqli_stmt_execute($check);
if (mysqli_num_rows(mysqli_stmt_get_result($check)) > 0) {
    echo json_encode(["success" => false, "message" => "Username sudah digunakan."]);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($check);

$stmt = mysqli_prepare($conn, "UPDATE users SET username=?, password=?, nama=?, no_telepon=? WHERE id=? AND role='guru'");
mysqli_stmt_bind_param($stmt, "ssssi", $username, $password, $nama, $no_telepon, $id);

if (mysqli_stmt_execute($stmt)) {
    // Check if ID exists (affected_rows can be 0 if data unchanged but ID exists)
    if (mysqli_affected_rows($conn) >= 0) {
        echo json_encode(["success" => true, "message" => "Data berhasil diupdate!"]);
    } else {
        echo json_encode(["success" => false, "message" => "ID guru tidak ditemukan."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Gagal mengupdate data: " . mysqli_error($conn)]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
