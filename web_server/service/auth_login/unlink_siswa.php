<?php
/**
 * Backend Unlink Siswa - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/unlink_siswa.php
 * 
 * Endpoint untuk menghapus hubungan siswa
 */

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST atau DELETE."
    ]);
    exit();
}

require_once '../config/koneksi.php';

$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    $data = [
        'primary_siswa_id' => $_POST['primary_siswa_id'] ?? 0,
        'linked_siswa_id' => $_POST['linked_siswa_id'] ?? 0
    ];
}

$primarySiswaId = (int) ($data['primary_siswa_id'] ?? 0);
$linkedSiswaId = (int) ($data['linked_siswa_id'] ?? 0);

if ($primarySiswaId <= 0 || $linkedSiswaId <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Primary siswa ID dan linked siswa ID harus diisi."
    ]);
    exit();
}

// Delete the link
$deleteQuery = "DELETE FROM siswa_terhubung 
                WHERE primary_siswa_id = ? AND linked_siswa_id = ?";
$stmt = mysqli_prepare($conn, $deleteQuery);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Terjadi kesalahan pada server."
    ]);
    exit();
}

mysqli_stmt_bind_param($stmt, "ii", $primarySiswaId, $linkedSiswaId);

if (mysqli_stmt_execute($stmt)) {
    if (mysqli_stmt_affected_rows($stmt) > 0) {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Hubungan siswa berhasil dihapus."
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Hubungan siswa tidak ditemukan."
        ]);
    }
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Gagal menghapus hubungan. Silakan coba lagi."
    ]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
