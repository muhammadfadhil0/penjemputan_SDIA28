<?php
/**
 * Update Kelas API
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Updates an existing class
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
    
    if (!$input || !isset($input['id'])) {
        throw new Exception('ID kelas wajib diisi');
    }
    
    $id = (int)$input['id'];
    $nama_kelas = isset($input['nama_kelas']) ? trim($input['nama_kelas']) : null;
    $tingkat = isset($input['tingkat']) ? (int)$input['tingkat'] : null;
    $tahun_ajaran = isset($input['tahun_ajaran']) ? trim($input['tahun_ajaran']) : null;
    
    // Check if kelas exists
    $check_query = "SELECT * FROM kelas WHERE id = ?";
    $check_stmt = mysqli_prepare($conn, $check_query);
    mysqli_stmt_bind_param($check_stmt, "i", $id);
    mysqli_stmt_execute($check_stmt);
    $check_result = mysqli_stmt_get_result($check_stmt);
    
    if (mysqli_num_rows($check_result) === 0) {
        throw new Exception('Kelas tidak ditemukan');
    }
    
    $existing = mysqli_fetch_assoc($check_result);
    
    // Use existing values if not provided
    $nama_kelas = $nama_kelas ?? $existing['nama_kelas'];
    $tingkat = $tingkat ?? $existing['tingkat'];
    $tahun_ajaran = $tahun_ajaran ?? $existing['tahun_ajaran'];
    
    if (empty($nama_kelas)) {
        throw new Exception('Nama kelas tidak boleh kosong');
    }
    
    // Auto-detect tingkat from nama_kelas if name changed
    if ($nama_kelas !== $existing['nama_kelas']) {
        preg_match('/Kelas\s*(\d+)/i', $nama_kelas, $matches);
        if (isset($matches[1])) {
            $tingkat = (int)$matches[1];
        }
    }
    
    // Check for duplicate (exclude current record)
    $dup_query = "SELECT id FROM kelas WHERE nama_kelas = ? AND tahun_ajaran = ? AND id != ?";
    $dup_stmt = mysqli_prepare($conn, $dup_query);
    mysqli_stmt_bind_param($dup_stmt, "ssi", $nama_kelas, $tahun_ajaran, $id);
    mysqli_stmt_execute($dup_stmt);
    $dup_result = mysqli_stmt_get_result($dup_stmt);
    
    if (mysqli_num_rows($dup_result) > 0) {
        throw new Exception('Kelas dengan nama yang sama sudah ada untuk tahun ajaran ini');
    }
    
    // Update kelas
    $update_query = "UPDATE kelas SET nama_kelas = ?, tingkat = ?, tahun_ajaran = ? WHERE id = ?";
    $stmt = mysqli_prepare($conn, $update_query);
    mysqli_stmt_bind_param($stmt, "sisi", $nama_kelas, $tingkat, $tahun_ajaran, $id);
    
    if (!mysqli_stmt_execute($stmt)) {
        throw new Exception("Gagal memperbarui kelas: " . mysqli_error($conn));
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Kelas berhasil diperbarui',
        'data' => [
            'id' => $id,
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
