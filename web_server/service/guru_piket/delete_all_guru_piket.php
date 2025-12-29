<?php
/**
 * Delete All Guru Piket - SDIA 28 Sistem Penjemputan
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
if (!isset($data['confirm']) || $data['confirm'] !== true) {
    echo json_encode(["success" => false, "message" => "Konfirmasi diperlukan."]);
    exit();
}

$result = mysqli_query($conn, "DELETE FROM users WHERE role = 'guru'");
$deleted = mysqli_affected_rows($conn);

if ($result) {
    echo json_encode(["success" => true, "message" => "Berhasil menghapus $deleted guru piket."]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal menghapus data."]);
}

mysqli_close($conn);
?>
