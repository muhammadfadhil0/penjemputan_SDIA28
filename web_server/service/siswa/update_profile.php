<?php
/**
 * API Endpoint untuk update profile siswa
 * Method: POST
 * Body: siswa_id, nama, nama_panggilan, password (optional)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Gunakan koneksi.php (MySQLi) yang sama dengan file lain
require_once __DIR__ . '/../config/koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed'
    ]);
    exit();
}

// Parse JSON body
$input = json_decode(file_get_contents('php://input'), true);

$siswa_id = isset($input['siswa_id']) ? intval($input['siswa_id']) : 0;
$nama = isset($input['nama']) ? trim($input['nama']) : '';
$nama_panggilan = isset($input['nama_panggilan']) ? trim($input['nama_panggilan']) : '';
$password = isset($input['password']) ? trim($input['password']) : '';

// Validasi
if ($siswa_id === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'ID siswa tidak valid'
    ]);
    exit();
}

if (empty($nama)) {
    echo json_encode([
        'success' => false,
        'message' => 'Nama lengkap harus diisi'
    ]);
    exit();
}

// Cek apakah siswa ada
$check_stmt = mysqli_prepare($conn, "SELECT id FROM siswa WHERE id = ?");
mysqli_stmt_bind_param($check_stmt, "i", $siswa_id);
mysqli_stmt_execute($check_stmt);
$check_result = mysqli_stmt_get_result($check_stmt);

if (mysqli_num_rows($check_result) === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Siswa tidak ditemukan'
    ]);
    mysqli_stmt_close($check_stmt);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($check_stmt);

// Update profile (dengan atau tanpa password)
if (!empty($password)) {
    // Update dengan password baru
    $update_stmt = mysqli_prepare($conn, "UPDATE siswa SET nama = ?, nama_panggilan = ?, password = ? WHERE id = ?");
    $nama_panggilan_val = !empty($nama_panggilan) ? $nama_panggilan : null;
    mysqli_stmt_bind_param($update_stmt, "sssi", $nama, $nama_panggilan_val, $password, $siswa_id);
} else {
    // Update tanpa password
    $update_stmt = mysqli_prepare($conn, "UPDATE siswa SET nama = ?, nama_panggilan = ? WHERE id = ?");
    $nama_panggilan_val = !empty($nama_panggilan) ? $nama_panggilan : null;
    mysqli_stmt_bind_param($update_stmt, "ssi", $nama, $nama_panggilan_val, $siswa_id);
}

if (!mysqli_stmt_execute($update_stmt)) {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal memperbarui profil: ' . mysqli_error($conn)
    ]);
    mysqli_stmt_close($update_stmt);
    mysqli_close($conn);
    exit();
}
mysqli_stmt_close($update_stmt);

// Ambil data siswa yang sudah diupdate beserta kelas
$select_stmt = mysqli_prepare($conn, "
    SELECT 
        s.id,
        s.username,
        s.nama,
        s.nama_panggilan,
        s.kelas_id,
        k.nama_kelas,
        k.tingkat,
        s.foto_url,
        s.no_telepon_ortu
    FROM siswa s
    JOIN kelas k ON s.kelas_id = k.id
    WHERE s.id = ?
");
mysqli_stmt_bind_param($select_stmt, "i", $siswa_id);
mysqli_stmt_execute($select_stmt);
$result = mysqli_stmt_get_result($select_stmt);
$siswa = mysqli_fetch_assoc($result);
mysqli_stmt_close($select_stmt);

echo json_encode([
    'success' => true,
    'message' => 'Profil berhasil diperbarui',
    'data' => [
        'id' => (int) $siswa['id'],
        'username' => $siswa['username'],
        'nama' => $siswa['nama'],
        'nama_panggilan' => $siswa['nama_panggilan'],
        'role' => 'siswa',
        'kelas_id' => (int) $siswa['kelas_id'],
        'nama_kelas' => $siswa['nama_kelas'],
        'tingkat' => (int) $siswa['tingkat'],
        'foto_url' => $siswa['foto_url'],
        'no_telepon_ortu' => $siswa['no_telepon_ortu']
    ]
]);

mysqli_close($conn);
?>
