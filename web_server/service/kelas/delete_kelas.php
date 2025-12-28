<?php
/**
 * Delete Kelas API
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Deletes a class from the database
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
    
    // Check if kelas exists
    $check_query = "SELECT * FROM kelas WHERE id = ?";
    $check_stmt = mysqli_prepare($conn, $check_query);
    mysqli_stmt_bind_param($check_stmt, "i", $id);
    mysqli_stmt_execute($check_stmt);
    $check_result = mysqli_stmt_get_result($check_stmt);
    
    if (mysqli_num_rows($check_result) === 0) {
        throw new Exception('Kelas tidak ditemukan');
    }
    
    $kelas = mysqli_fetch_assoc($check_result);
    
    // Check if there are students in this class
    $siswa_query = "SELECT COUNT(*) as total FROM siswa WHERE kelas_id = ?";
    $siswa_stmt = mysqli_prepare($conn, $siswa_query);
    mysqli_stmt_bind_param($siswa_stmt, "i", $id);
    mysqli_stmt_execute($siswa_stmt);
    $siswa_result = mysqli_stmt_get_result($siswa_stmt);
    $siswa_count = mysqli_fetch_assoc($siswa_result)['total'];
    
    if ($siswa_count > 0) {
        throw new Exception("Tidak dapat menghapus kelas '{$kelas['nama_kelas']}' karena masih memiliki {$siswa_count} siswa. Pindahkan siswa terlebih dahulu.");
    }
    
    // Delete kelas (CASCADE will handle related jadwal_kelas and login_kelas)
    $delete_query = "DELETE FROM kelas WHERE id = ?";
    $stmt = mysqli_prepare($conn, $delete_query);
    mysqli_stmt_bind_param($stmt, "i", $id);
    
    if (!mysqli_stmt_execute($stmt)) {
        throw new Exception("Gagal menghapus kelas: " . mysqli_error($conn));
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Kelas '{$kelas['nama_kelas']}' berhasil dihapus"
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
