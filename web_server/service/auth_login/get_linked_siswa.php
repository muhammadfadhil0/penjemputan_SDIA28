<?php
/**
 * Backend Get Linked Siswa - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/get_linked_siswa.php
 * 
 * Endpoint untuk mendapatkan daftar siswa yang terhubung
 */

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/koneksi.php';

// Accept both GET and POST
$primarySiswaId = 0;

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $primarySiswaId = (int) ($_GET['primary_siswa_id'] ?? 0);
} else {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    $primarySiswaId = (int) ($data['primary_siswa_id'] ?? $_POST['primary_siswa_id'] ?? 0);
}

if ($primarySiswaId <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Primary siswa ID harus diisi."
    ]);
    exit();
}

// Get all linked students
$query = "SELECT s.id, s.nama, s.nama_panggilan, s.username, 
                 s.kelas_id, s.foto_url, s.no_telepon_ortu,
                 k.nama_kelas, k.tingkat,
                 st.created_at as linked_at
          FROM siswa_terhubung st
          JOIN siswa s ON st.linked_siswa_id = s.id
          JOIN kelas k ON s.kelas_id = k.id
          WHERE st.primary_siswa_id = ?
          ORDER BY st.created_at ASC";

$stmt = mysqli_prepare($conn, $query);

if (!$stmt) {
    // Table might not exist yet, return empty array
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Berhasil mengambil data.",
        "data" => []
    ]);
    exit();
}

mysqli_stmt_bind_param($stmt, "i", $primarySiswaId);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

$linkedStudents = [];

while ($row = mysqli_fetch_assoc($result)) {
    $linkedStudents[] = [
        "id" => (int) $row['id'],
        "username" => $row['username'],
        "nama" => $row['nama'],
        "nama_panggilan" => $row['nama_panggilan'],
        "kelas_id" => (int) $row['kelas_id'],
        "nama_kelas" => $row['nama_kelas'],
        "tingkat" => (int) $row['tingkat'],
        "foto_url" => $row['foto_url'],
        "no_telepon_ortu" => $row['no_telepon_ortu'],
        "linked_at" => $row['linked_at']
    ];
}

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Berhasil mengambil data.",
    "data" => $linkedStudents
]);

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
