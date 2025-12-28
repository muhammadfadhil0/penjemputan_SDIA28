<?php
/**
 * Get All Kelas API
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Returns all classes with student count
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
    // Get all kelas with student count using LEFT JOIN
    $query = "
        SELECT 
            k.id, 
            k.nama_kelas, 
            k.tingkat, 
            k.tahun_ajaran,
            k.created_at,
            COUNT(s.id) as jumlah_siswa
        FROM kelas k
        LEFT JOIN siswa s ON k.id = s.kelas_id
        GROUP BY k.id, k.nama_kelas, k.tingkat, k.tahun_ajaran, k.created_at
        ORDER BY k.tingkat ASC, k.nama_kelas ASC
    ";
    
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        throw new Exception("Query error: " . mysqli_error($conn));
    }
    
    $kelas = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $kelas[] = [
            'id' => (int)$row['id'],
            'nama_kelas' => $row['nama_kelas'],
            'tingkat' => (int)$row['tingkat'],
            'tahun_ajaran' => $row['tahun_ajaran'],
            'jumlah_siswa' => (int)$row['jumlah_siswa'],
            'created_at' => $row['created_at']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $kelas,
        'total' => count($kelas)
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
