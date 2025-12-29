<?php
/**
 * Add Guru Piket - SDIA 28 Sistem Penjemputan
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

$input = file_get_contents("php://input");
$data = json_decode($input, true);
if (!$data) {
    $data = ['username' => $_POST['username'] ?? '', 'password' => $_POST['password'] ?? '', 
             'nama' => $_POST['nama'] ?? '', 'no_telepon' => $_POST['no_telepon'] ?? ''];
}

$username = trim($data['username'] ?? '');
$password = trim($data['password'] ?? '');
$nama = trim($data['nama'] ?? '');
$no_telepon = trim($data['no_telepon'] ?? '');

if (empty($username) || empty($password) || empty($nama)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Username, password, dan nama harus diisi."]);
    exit();
}

// Check duplicate username
$check = mysqli_prepare($conn, "SELECT id FROM users WHERE username = ?");
mysqli_stmt_bind_param($check, "s", $username);
mysqli_stmt_execute($check);
if (mysqli_num_rows(mysqli_stmt_get_result($check)) > 0) {
    echo json_encode(["success" => false, "message" => "Username sudah digunakan."]);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($check);

$stmt = mysqli_prepare($conn, "INSERT INTO users (username, password, role, nama, no_telepon) VALUES (?, ?, 'guru', ?, ?)");
mysqli_stmt_bind_param($stmt, "ssss", $username, $password, $nama, $no_telepon);

if (mysqli_stmt_execute($stmt)) {
    echo json_encode(["success" => true, "message" => "Guru piket berhasil ditambahkan!", "id" => mysqli_insert_id($conn)]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal menambahkan: " . mysqli_error($conn)]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
