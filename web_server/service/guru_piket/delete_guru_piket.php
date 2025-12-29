<?php
/**
 * Delete Guru Piket - SDIA 28 Sistem Penjemputan
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

if ($id <= 0) {
    echo json_encode(["success" => false, "message" => "ID tidak valid."]);
    exit();
}

$stmt = mysqli_prepare($conn, "DELETE FROM users WHERE id = ? AND role = 'guru'");
mysqli_stmt_bind_param($stmt, "i", $id);

if (mysqli_stmt_execute($stmt) && mysqli_affected_rows($conn) > 0) {
    echo json_encode(["success" => true, "message" => "Guru piket berhasil dihapus!"]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal menghapus atau data tidak ditemukan."]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
