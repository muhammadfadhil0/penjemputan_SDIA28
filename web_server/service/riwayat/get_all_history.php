<?php
/**
 * API Endpoint: Get All Riwayat Penjemputan
 * 
 * Mengambil semua riwayat penjemputan (untuk admin/monitor)
 * 
 * Method: GET/POST
 * Parameters:
 *   - tanggal (optional): Filter berdasarkan tanggal spesifik (format: YYYY-MM-DD)
 *   - limit (optional): Jumlah data yang diambil (default: 100)
 *   - search (optional): Cari berdasarkan nama siswa
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
$tanggal = null;
$limit = 100;
$search = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $tanggal = isset($input['tanggal']) ? $input['tanggal'] : null;
    $limit = isset($input['limit']) ? intval($input['limit']) : 100;
    $search = isset($input['search']) ? $input['search'] : null;
    $offset = isset($input['offset']) ? intval($input['offset']) : 0;
} else { // GET request
    $tanggal = isset($_GET['tanggal']) ? $_GET['tanggal'] : null;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $search = isset($_GET['search']) ? $_GET['search'] : null;
    $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
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
                s.foto_url,
                k.nama_kelas
            FROM permintaan_jemput pj
            JOIN siswa s ON pj.siswa_id = s.id
            JOIN kelas k ON s.kelas_id = k.id";
    
    $conditions = [];
    $params = [];
    $types = "";
    
    // Add date filter if provided
    if ($tanggal) {
        $conditions[] = "DATE(pj.waktu_request) = ?";
        $params[] = $tanggal;
        $types .= "s";
    }
    
    // Add search filter if provided
    if ($search) {
        $conditions[] = "s.nama LIKE ?";
        $params[] = "%$search%";
        $types .= "s";
    }
    
    if (!empty($conditions)) {
        $sql .= " WHERE " . implode(" AND ", $conditions);
    }
    
    // Order by most recent first and add limit/offset
    $sql .= " ORDER BY pj.waktu_request DESC LIMIT ? OFFSET ?";
    $params[] = $limit;
    $params[] = $offset;
    $types .= "ii";
    
    $stmt = $conn->prepare($sql);
    
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $riwayat = [];
    while ($row = $result->fetch_assoc()) {
        // Format penjemput display
        $penjemputDisplay = ucfirst($row['penjemput']);
        if ($row['penjemput_detail']) {
            $penjemputDisplay .= ' (' . $row['penjemput_detail'] . ')';
        }
        
        // Determine catatan based on status
        $catatan = '';
        
        switch ($row['status']) {
            case 'dijemput':
                $catatan = 'Tepat waktu';
                break;
            case 'dipanggil':
                $catatan = 'Dipanggil';
                break;
            case 'menunggu':
                $catatan = 'Menunggu';
                break;
            case 'dibatalkan':
                $catatan = 'Dibatalkan';
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
            'nama_kelas' => $row['nama_kelas'],
            'foto_url' => $row['foto_url']
        ];
    }
    
    $stmt->close();
    
    // Get summary stats (Today)
    // Count total today
    $today = date('Y-m-d');
    $sqlToday = "SELECT COUNT(*) as total FROM permintaan_jemput WHERE DATE(waktu_request) = '$today'";
    $resultToday = $conn->query($sqlToday);
    $countToday = $resultToday->fetch_assoc()['total'];
    
    
    echo json_encode([
        'success' => true,
        'message' => 'Data riwayat berhasil diambil',
        'count' => count($riwayat),
        'stats' => [
            'today' => $countToday
        ],
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
