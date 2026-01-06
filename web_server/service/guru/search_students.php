<?php
/**
 * Search Students for Guru Piket
 * SDIA 28 - Sistem Penjemputan Siswa
 * 
 * Endpoint to search students by name and/or filter by class
 * Also checks if student has active pickup request
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
    // Get search parameters
    $query_param = isset($_GET['q']) ? trim($_GET['q']) : '';
    $kelas_id = isset($_GET['kelas_id']) ? (int)$_GET['kelas_id'] : null;
    $available_only = isset($_GET['available_only']) && $_GET['available_only'] === 'true';
    
    // Build the query - using correct table name 'permintaan_jemput'
    $sql = "
        SELECT 
            s.id,
            s.nama,
            s.nama_panggilan,
            k.nama_kelas,
            s.kelas_id,
            k.tingkat,
            s.foto_url,
            (
                SELECT COUNT(*) 
                FROM permintaan_jemput pj 
                WHERE pj.siswa_id = s.id 
                AND pj.status IN ('menunggu', 'dipanggil')
                AND DATE(pj.waktu_request) = CURDATE()
            ) as active_requests,
            (
                SELECT pj.status 
                FROM permintaan_jemput pj 
                WHERE pj.siswa_id = s.id 
                AND pj.status IN ('menunggu', 'dipanggil')
                AND DATE(pj.waktu_request) = CURDATE()
                ORDER BY pj.waktu_request DESC 
                LIMIT 1
            ) as current_status
        FROM siswa s
        LEFT JOIN kelas k ON s.kelas_id = k.id
        WHERE 1=1
    ";
    
    $params = [];
    $types = '';
    
    // Add name search condition
    if (!empty($query_param)) {
        $sql .= " AND (s.nama LIKE ? OR s.nama_panggilan LIKE ?)";
        $search_term = "%{$query_param}%";
        $params[] = $search_term;
        $params[] = $search_term;
        $types .= 'ss';
    }
    
    // Add class filter condition
    if ($kelas_id !== null && $kelas_id > 0) {
        $sql .= " AND s.kelas_id = ?";
        $params[] = $kelas_id;
        $types .= 'i';
    }
    
    // If available_only, exclude students with active requests
    if ($available_only) {
        $sql .= " AND NOT EXISTS (
            SELECT 1 FROM permintaan_jemput pj 
            WHERE pj.siswa_id = s.id 
            AND pj.status IN ('menunggu', 'dipanggil')
            AND DATE(pj.waktu_request) = CURDATE()
        )";
    }
    
    $sql .= " ORDER BY k.tingkat ASC, k.nama_kelas ASC, s.nama ASC LIMIT 50";
    
    // Prepare and execute query
    $stmt = mysqli_prepare($conn, $sql);
    
    if (!$stmt) {
        throw new Exception("Prepare error: " . mysqli_error($conn));
    }
    
    if (!empty($params)) {
        mysqli_stmt_bind_param($stmt, $types, ...$params);
    }
    
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    
    $students = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $students[] = [
            'id' => (int)$row['id'],
            'nama' => $row['nama'],
            'nama_panggilan' => $row['nama_panggilan'],
            'nama_kelas' => $row['nama_kelas'] ?? 'Tanpa Kelas',
            'kelas_id' => (int)$row['kelas_id'],
            'tingkat' => (int)($row['tingkat'] ?? 0),
            'foto_url' => $row['foto_url'],
            'has_active_request' => (int)$row['active_requests'] > 0,
            'current_status' => $row['current_status']
        ];
    }
    
    mysqli_stmt_close($stmt);
    
    echo json_encode([
        'success' => true,
        'data' => $students,
        'total' => count($students)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mencari siswa: ' . $e->getMessage()
    ]);
}

mysqli_close($conn);
?>

