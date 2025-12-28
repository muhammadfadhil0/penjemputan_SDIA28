<?php
/**
 * Add Kelas API
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Adds a new class to the database
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/koneksi.php';

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['nama_kelas'])) {
        throw new Exception('Nama kelas wajib diisi');
    }
    
    $nama_kelas = trim($input['nama_kelas']);
    $tingkat = isset($input['tingkat']) ? (int)$input['tingkat'] : 1;
    $tahun_ajaran = isset($input['tahun_ajaran']) ? trim($input['tahun_ajaran']) : date('Y') . '/' . (date('Y') + 1);
    
    if (empty($nama_kelas)) {
        throw new Exception('Nama kelas tidak boleh kosong');
    }
    
    // Auto-detect tingkat from nama_kelas if not provided
    if (!isset($input['tingkat'])) {
        preg_match('/Kelas\s*(\d+)/i', $nama_kelas, $matches);
        if (isset($matches[1])) {
            $tingkat = (int)$matches[1];
        }
    }
    
    // Check if kelas already exists
    $check_query = "SELECT id FROM kelas WHERE nama_kelas = ? AND tahun_ajaran = ?";
    $check_stmt = mysqli_prepare($conn, $check_query);
    mysqli_stmt_bind_param($check_stmt, "ss", $nama_kelas, $tahun_ajaran);
    mysqli_stmt_execute($check_stmt);
    $check_result = mysqli_stmt_get_result($check_stmt);
    
    if (mysqli_num_rows($check_result) > 0) {
        throw new Exception('Kelas dengan nama yang sama sudah ada untuk tahun ajaran ini');
    }
    
    // Insert new kelas
    $insert_query = "INSERT INTO kelas (nama_kelas, tingkat, tahun_ajaran) VALUES (?, ?, ?)";
    $stmt = mysqli_prepare($conn, $insert_query);
    mysqli_stmt_bind_param($stmt, "sis", $nama_kelas, $tingkat, $tahun_ajaran);
    
    if (!mysqli_stmt_execute($stmt)) {
        throw new Exception("Gagal menambahkan kelas: " . mysqli_error($conn));
    }
    
    $new_id = mysqli_insert_id($conn);
    
    echo json_encode([
        'success' => true,
        'message' => 'Kelas berhasil ditambahkan',
        'data' => [
            'id' => $new_id,
            'nama_kelas' => $nama_kelas,
            'tingkat' => $tingkat,
            'tahun_ajaran' => $tahun_ajaran
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

mysqli_close($conn);
?>
