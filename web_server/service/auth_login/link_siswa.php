<?php
/**
 * Backend Link Siswa - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/link_siswa.php
 * 
 * Endpoint untuk menghubungkan siswa lain ke akun utama
 */

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST."
    ]);
    exit();
}

require_once '../config/koneksi.php';

$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    $data = [
        'primary_siswa_id' => $_POST['primary_siswa_id'] ?? 0,
        'username' => $_POST['username'] ?? '',
        'password' => $_POST['password'] ?? ''
    ];
}

$primarySiswaId = (int) ($data['primary_siswa_id'] ?? 0);
$username = trim($data['username'] ?? '');
$password = trim($data['password'] ?? '');

if ($primarySiswaId <= 0 || empty($username) || empty($password)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Primary siswa ID, username, dan password harus diisi."
    ]);
    exit();
}

// Verify the secondary student credentials
$query = "SELECT s.id, s.nama, s.nama_panggilan, s.username, s.password, 
                 s.kelas_id, s.foto_url, s.no_telepon_ortu,
                 k.nama_kelas, k.tingkat
          FROM siswa s
          JOIN kelas k ON s.kelas_id = k.id
          WHERE s.username = ?";

$stmt = mysqli_prepare($conn, $query);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Terjadi kesalahan pada server."
    ]);
    exit();
}

mysqli_stmt_bind_param($stmt, "s", $username);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if ($row = mysqli_fetch_assoc($result)) {
    // Verify password
    if ($password !== $row['password']) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Username atau password salah."
        ]);
        exit();
    }
    
    $linkedSiswaId = (int) $row['id'];
    
    // Check if linking to self
    if ($linkedSiswaId === $primarySiswaId) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Tidak dapat menghubungkan akun dengan diri sendiri."
        ]);
        exit();
    }
    
    // Check if already linked
    $checkQuery = "SELECT id FROM siswa_terhubung 
                   WHERE primary_siswa_id = ? AND linked_siswa_id = ?";
    $checkStmt = mysqli_prepare($conn, $checkQuery);
    mysqli_stmt_bind_param($checkStmt, "ii", $primarySiswaId, $linkedSiswaId);
    mysqli_stmt_execute($checkStmt);
    $checkResult = mysqli_stmt_get_result($checkStmt);
    
    if (mysqli_fetch_assoc($checkResult)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Murid ini sudah terhubung sebelumnya."
        ]);
        exit();
    }
    mysqli_stmt_close($checkStmt);
    
    // Create the link
    $insertQuery = "INSERT INTO siswa_terhubung (primary_siswa_id, linked_siswa_id) VALUES (?, ?)";
    $insertStmt = mysqli_prepare($conn, $insertQuery);
    
    if (!$insertStmt) {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal membuat koneksi. Pastikan tabel siswa_terhubung sudah ada."
        ]);
        exit();
    }
    
    mysqli_stmt_bind_param($insertStmt, "ii", $primarySiswaId, $linkedSiswaId);
    
    if (mysqli_stmt_execute($insertStmt)) {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Murid berhasil dihubungkan!",
            "data" => [
                "id" => $linkedSiswaId,
                "username" => $row['username'],
                "nama" => $row['nama'],
                "nama_panggilan" => $row['nama_panggilan'],
                "kelas_id" => (int) $row['kelas_id'],
                "nama_kelas" => $row['nama_kelas'],
                "tingkat" => (int) $row['tingkat'],
                "foto_url" => $row['foto_url'],
                "no_telepon_ortu" => $row['no_telepon_ortu']
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal menyimpan data. Silakan coba lagi."
        ]);
    }
    
    mysqli_stmt_close($insertStmt);
} else {
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "message" => "Username atau password salah."
    ]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
