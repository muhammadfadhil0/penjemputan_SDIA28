<?php
/**
 * Get All Guru Piket - SDIA 28 Sistem Penjemputan
 */
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method tidak diizinkan."]);
    exit();
}

require_once '../config/koneksi.php';

$query = "SELECT id, username, password, role, nama, no_telepon, foto, created_at 
          FROM users WHERE role = 'guru' ORDER BY nama ASC";
$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Gagal mengambil data: " . mysqli_error($conn)]);
    mysqli_close($conn);
    exit();
}

$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = [
        "id" => (int) $row['id'],
        "username" => $row['username'],
        "password" => $row['password'],
        "role" => $row['role'],
        "nama" => $row['nama'],
        "no_telepon" => $row['no_telepon'] ?? '',
        "foto" => $row['foto'] ?? '',
        "created_at" => $row['created_at']
    ];
}

echo json_encode(["success" => true, "total" => count($data), "data" => $data]);
mysqli_close($conn);
?>
