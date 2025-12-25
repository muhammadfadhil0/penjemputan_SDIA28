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

require_once __DIR__ . '/../config/database.php';

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

try {
    // Cek apakah siswa ada
    $stmt = $pdo->prepare("SELECT id FROM siswa WHERE id = ?");
    $stmt->execute([$siswa_id]);
    if (!$stmt->fetch()) {
        echo json_encode([
            'success' => false,
            'message' => 'Siswa tidak ditemukan'
        ]);
        exit();
    }

    // Update profile (dengan atau tanpa password)
    if (!empty($password)) {
        // Update dengan password baru
        $stmt = $pdo->prepare("
            UPDATE siswa 
            SET nama = ?, nama_panggilan = ?, password = ?
            WHERE id = ?
        ");
        $stmt->execute([$nama, $nama_panggilan ?: null, $password, $siswa_id]);
    } else {
        // Update tanpa password
        $stmt = $pdo->prepare("
            UPDATE siswa 
            SET nama = ?, nama_panggilan = ?
            WHERE id = ?
        ");
        $stmt->execute([$nama, $nama_panggilan ?: null, $siswa_id]);
    }

    // Ambil data siswa yang sudah diupdate beserta kelas
    $stmt = $pdo->prepare("
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
    $stmt->execute([$siswa_id]);
    $siswa = $stmt->fetch(PDO::FETCH_ASSOC);

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

} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Terjadi kesalahan: ' . $e->getMessage()
    ]);
}
?>
