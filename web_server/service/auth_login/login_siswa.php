<?php
/**
 * Backend Login Siswa - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/login_siswa.php
 * 
 * Endpoint untuk proses autentikasi siswa (dipakai orang tua login via akun siswa)
 * Khusus untuk Flutter App
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
        'username' => $_POST['username'] ?? '',
        'password' => $_POST['password'] ?? ''
    ];
}

// Validasi input
$username = trim($data['username'] ?? '');
$password = trim($data['password'] ?? '');

if (empty($username) || empty($password)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Username dan password harus diisi."
    ]);
    exit();
}

// Query untuk mencari siswa dengan join ke kelas
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
    // Verifikasi password
    // Saat ini menggunakan plain text comparison
    // Untuk produksi: gunakan password_verify($password, $row['password'])
    if ($password === $row['password']) {
        // Login berhasil
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Login berhasil!",
            "data" => [
                "id" => (int) $row['id'],
                "username" => $row['username'],
                "nama" => $row['nama'],
                "nama_panggilan" => $row['nama_panggilan'],
                "role" => "siswa", // Role tetap siswa
                "kelas_id" => (int) $row['kelas_id'],
                "nama_kelas" => $row['nama_kelas'],
                "tingkat" => (int) $row['tingkat'],
                "foto_url" => $row['foto_url'],
                "no_telepon_ortu" => $row['no_telepon_ortu']
            ]
        ]);
    } else {
        // Password salah
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Username atau password salah."
        ]);
    }
} else {
    // Siswa tidak ditemukan
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "message" => "Username atau password salah."
    ]);
}

// Tutup statement dan koneksi
mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
