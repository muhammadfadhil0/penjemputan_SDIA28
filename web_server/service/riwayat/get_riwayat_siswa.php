<?php
/**
 * API Endpoint: Get Riwayat Penjemputan Siswa
 * 
 * Mengambil riwayat penjemputan untuk siswa tertentu
 * 
 * Method: GET/POST
 * Parameters:
 *   - siswa_id: ID siswa (required)
 *   - tanggal (optional): Filter berdasarkan tanggal spesifik (format: YYYY-MM-DD)
 *   - limit (optional): Jumlah data yang diambil (default: 50)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once '../config/koneksi.php';

// Get parameters from GET or POST
$siswa_id = null;
$tanggal = null;
$limit = 50;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $siswa_id = isset($input['siswa_id']) ? intval($input['siswa_id']) : null;
    $tanggal = isset($input['tanggal']) ? $input['tanggal'] : null;
    $limit = isset($input['limit']) ? intval($input['limit']) : 50;
} else {
    $siswa_id = isset($_GET['siswa_id']) ? intval($_GET['siswa_id']) : null;
    $tanggal = isset($_GET['tanggal']) ? $_GET['tanggal'] : null;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;
}

// Validate siswa_id
if (!$siswa_id) {
    echo json_encode([
        'success' => false,
        'message' => 'Parameter siswa_id diperlukan'
    ]);
    exit();
}

try {
    // Build query
    $sql = "SELECT 
                pj.id,
                pj.siswa_id,
                pj.penjemput,
                pj.penjemput_detail,
                pj.estimasi_waktu,
                pj.waktu_estimasi,
                pj.status,
                pj.nomor_antrian,
                pj.waktu_request,
                pj.waktu_dipanggil,
                pj.waktu_dijemput,
                s.nama AS nama_siswa,
                k.nama_kelas
            FROM permintaan_jemput pj
            JOIN siswa s ON pj.siswa_id = s.id
            JOIN kelas k ON s.kelas_id = k.id
            WHERE pj.siswa_id = ?";
    
    $params = [$siswa_id];
    $types = "i";
    
    // Add date filter if provided
    if ($tanggal) {
        $sql .= " AND DATE(pj.waktu_request) = ?";
        $params[] = $tanggal;
        $types .= "s";
    }
    
    // Order by most recent first, completed/picked up status
    $sql .= " ORDER BY pj.waktu_request DESC LIMIT ?";
    $params[] = $limit;
    $types .= "i";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $riwayat = [];
    while ($row = $result->fetch_assoc()) {
        // Format penjemput display
        $penjemputDisplay = ucfirst($row['penjemput']);
        if ($row['penjemput_detail']) {
            $penjemputDisplay .= ' (' . $row['penjemput_detail'] . ')';
        }
        
        // Determine catatan based on status and timing
        $catatan = '';
        $isSelesai = false;
        
        switch ($row['status']) {
            case 'dijemput':
                $catatan = 'Tepat waktu';
                $isSelesai = true;
                break;
            case 'dipanggil':
                $catatan = 'Dipanggil';
                $isSelesai = false;
                break;
            case 'menunggu':
                $catatan = 'Menunggu';
                $isSelesai = false;
                break;
            case 'dibatalkan':
                $catatan = 'Dibatalkan';
                $isSelesai = false;
                break;
            default:
                $catatan = ucfirst($row['status']);
        }
        
        // Format waktu_request to extract time
        $waktuRequest = new DateTime($row['waktu_request']);
        $waktu = $waktuRequest->format('H:i');
        $tanggalObj = $waktuRequest->format('Y-m-d');
        
        // Indonesian date format
        $months = [
            '01' => 'Januari', '02' => 'Februari', '03' => 'Maret',
            '04' => 'April', '05' => 'Mei', '06' => 'Juni',
            '07' => 'Juli', '08' => 'Agustus', '09' => 'September',
            '10' => 'Oktober', '11' => 'November', '12' => 'Desember'
        ];
        
        $day = intval($waktuRequest->format('d'));
        $month = $months[$waktuRequest->format('m')];
        $year = $waktuRequest->format('Y');
        $tanggalText = "$day $month $year";
        
        $riwayat[] = [
            'id' => intval($row['id']),
            'siswa_id' => intval($row['siswa_id']),
            'tanggal' => $tanggalObj,
            'tanggalText' => $tanggalText,
            'waktu' => $waktu,
            'penjemput' => $penjemputDisplay,
            'penjemput_raw' => $row['penjemput'],
            'penjemput_detail' => $row['penjemput_detail'],
            'status' => $row['status'],
            'catatan' => $catatan,
            'nomor_antrian' => intval($row['nomor_antrian']),
            'waktu_request' => $row['waktu_request'],
            'waktu_dipanggil' => $row['waktu_dipanggil'],
            'waktu_dijemput' => $row['waktu_dijemput'],
            'nama_siswa' => $row['nama_siswa'],
            'nama_kelas' => $row['nama_kelas']
        ];
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'message' => 'Data riwayat berhasil diambil',
        'count' => count($riwayat),
        'data' => $riwayat
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Terjadi kesalahan: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
