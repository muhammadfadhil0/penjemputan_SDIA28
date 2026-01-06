<?php
/**
 * Get Kelas List for Guru Piket
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Endpoint to get list of all classes for dropdown
 */

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/koneksi.php';

try {
    // Get all classes ordered by tingkat and name
    $query = "
        SELECT 
            id, 
            nama_kelas as nama, 
            tingkat
        FROM kelas 
        ORDER BY tingkat ASC, nama_kelas ASC
    ";
    
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        throw new Exception("Query error: " . mysqli_error($conn));
    }
    
    $kelas = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $kelas[] = [
            'id' => (int)$row['id'],
            'nama' => $row['nama'],
            'tingkat' => (int)$row['tingkat']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $kelas
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengambil data kelas: ' . $e->getMessage()
    ]);
}

mysqli_close($conn);
?>
