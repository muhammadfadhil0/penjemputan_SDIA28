<?php
/**
 * Backend Login - SDIA 28 Sistem Penjemputan
 * File: service/auth_login/login.php
 * 
 * Endpoint untuk proses autentikasi user (guru piket)
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

// PERTAMA: Cek di tabel login_kelas
$queryKelas = "SELECT lk.id, lk.kelas_id, lk.username, lk.password, 
                      k.nama_kelas, k.tingkat, k.tahun_ajaran
               FROM login_kelas lk
               JOIN kelas k ON lk.kelas_id = k.id
               WHERE lk.username = ?";

$stmtKelas = mysqli_prepare($conn, $queryKelas);

if ($stmtKelas) {
    mysqli_stmt_bind_param($stmtKelas, "s", $username);
    mysqli_stmt_execute($stmtKelas);
    $resultKelas = mysqli_stmt_get_result($stmtKelas);

    if ($rowKelas = mysqli_fetch_assoc($resultKelas)) {
        // User ditemukan di login_kelas, verifikasi password
        if ($password === $rowKelas['password']) {
            // Login berhasil sebagai kelas
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Login berhasil!",
                "user_type" => "kelas",
                "data" => [
                    "id" => (int) $rowKelas['id'],
                    "username" => $rowKelas['username'],
                    "kelas_id" => (int) $rowKelas['kelas_id'],
                    "nama_kelas" => $rowKelas['nama_kelas'],
                    "tingkat" => (int) $rowKelas['tingkat'],
                    "tahun_ajaran" => $rowKelas['tahun_ajaran'],
                    "role" => "kelas"
                ]
            ]);
            mysqli_stmt_close($stmtKelas);
            mysqli_close($conn);
            exit();
        }
    }
    mysqli_stmt_close($stmtKelas);
}

// KEDUA: Jika tidak ditemukan di login_kelas, cek di tabel users
// Query untuk mencari user
// Catatan: Untuk produksi, gunakan password_hash() dan password_verify()
$query = "SELECT id, username, password, role, nama, no_telepon, foto 
          FROM users 
          WHERE username = ? AND role IN ('guru', 'class_viewer')";

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
            "user_type" => "guru",
            "data" => [
                "id" => (int) $row['id'],
                "username" => $row['username'],
                "nama" => $row['nama'],
                "role" => $row['role'],
                "no_telepon" => $row['no_telepon'],
                "foto" => $row['foto'] ?? null
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
    // User tidak ditemukan di kedua tabel
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
