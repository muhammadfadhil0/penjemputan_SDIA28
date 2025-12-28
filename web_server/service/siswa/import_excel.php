<?php
/**
 * API Endpoint: Import Siswa from Excel (XLSX) - Preview & Save
 * 
 * Method: POST
 * Actions:
 * 1. action='preview' & file -> Returns parsed data with validation
 * 2. action='save' & data (JSON) -> Inserts data into DB
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/koneksi.php';
require_once '../lib/SimpleXLSX.php';

use Shuchkin\SimpleXLSX;

$response = [
    'success' => false,
    'message' => 'Terjadi kesalahan sistem',
    'data' => []
];

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    $action = $_POST['action'] ?? '';

    // Get all Kelas map for validation (name -> id)
    $kelasMap = [];
    $kelasMapNormalized = []; // normalized version for flexible matching
    $kelasResult = $conn->query("SELECT id, nama_kelas FROM kelas");
    while ($row = $kelasResult->fetch_assoc()) {
        $original = trim($row['nama_kelas']);
        $kelasMap[$original] = $row['id']; // Keep original for display
        
        // Create normalized versions for matching
        $normalized = strtoupper(trim($original));
        $kelasMapNormalized[$normalized] = ['id' => $row['id'], 'nama' => $original];
        
        // Also add version without "Kelas " prefix
        $withoutPrefix = preg_replace('/^KELAS\s+/i', '', $normalized);
        if ($withoutPrefix !== $normalized) {
            $kelasMapNormalized[$withoutPrefix] = ['id' => $row['id'], 'nama' => $original];
        }
        
        // Add version with minimal spaces (e.g., "1ABUBAKAR")
        $noSpaces = preg_replace('/\s+/', '', $normalized);
        $kelasMapNormalized[$noSpaces] = ['id' => $row['id'], 'nama' => $original];
        
        // Add version without "Kelas" and minimal spaces
        $withoutPrefixNoSpaces = preg_replace('/\s+/', '', $withoutPrefix);
        $kelasMapNormalized[$withoutPrefixNoSpaces] = ['id' => $row['id'], 'nama' => $original];
    }
    
    // Helper function to find kelas
    function findKelas($inputKelas, $kelasMapNormalized) {
        if (empty($inputKelas)) return null;
        
        $normalized = strtoupper(trim($inputKelas));
        
        // Try exact match first
        if (isset($kelasMapNormalized[$normalized])) {
            return $kelasMapNormalized[$normalized];
        }
        
        // Try without "Kelas " prefix
        $withoutPrefix = preg_replace('/^KELAS\s+/i', '', $normalized);
        if (isset($kelasMapNormalized[$withoutPrefix])) {
            return $kelasMapNormalized[$withoutPrefix];
        }
        
        // Try with minimal spaces
        $noSpaces = preg_replace('/\s+/', '', $normalized);
        if (isset($kelasMapNormalized[$noSpaces])) {
            return $kelasMapNormalized[$noSpaces];
        }
        
        // Try partial match - check if any key contains the input
        foreach ($kelasMapNormalized as $key => $value) {
            if (strpos($key, $withoutPrefix) !== false || strpos($withoutPrefix, $key) !== false) {
                return $value;
            }
        }
        
        return null;
    }

    if ($action === 'preview') {
        // PREVIEW MODE
        if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            throw new Exception('File tidak ditemukan atau terjadi error saat upload');
        }

        $file = $_FILES['file'];
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

        if ($ext !== 'xlsx') {
            throw new Exception('Format file harus Excel (.xlsx).');
        }

        if ($xlsx = SimpleXLSX::parse($file['tmp_name'])) {
            $dataRows = $xlsx->rows();
        } else {
            throw new Exception(SimpleXLSX::parseError());
        }

        $previewData = [];
        $headerMap = [];
        $rowNumber = 0;

        foreach ($dataRows as $data) {
            $rowNumber++;
            
            // First row is always header - detect column mapping
            if ($rowNumber === 1) {
                foreach ($data as $colIndex => $colName) {
                    $colNameLower = strtolower(trim($colName));
                    
                    // Map various header names to standard fields
                    if (in_array($colNameLower, ['nama', 'nama lengkap', 'nama siswa', 'nama anak'])) {
                        $headerMap['nama'] = $colIndex;
                    } elseif (in_array($colNameLower, ['panggilan', 'nama panggilan', 'nick', 'nickname'])) {
                        $headerMap['panggilan'] = $colIndex;
                    } elseif (in_array($colNameLower, ['kelas', 'class', 'rombel'])) {
                        $headerMap['kelas'] = $colIndex;
                    } elseif (in_array($colNameLower, ['no hp', 'no hp ortu', 'no telepon', 'telepon', 'hp', 'no telepon ortu', 'phone'])) {
                        $headerMap['no_hp'] = $colIndex;
                    }
                    // Skip 'no' column - just numbering
                }
                
                // Validate required columns
                if (!isset($headerMap['nama'])) {
                    throw new Exception('Kolom "Nama" atau "Nama Lengkap" tidak ditemukan di header Excel');
                }
                
                continue; // Skip header row for data
            }

            // Get values based on header mapping
            $nama = isset($headerMap['nama']) ? trim($data[$headerMap['nama']] ?? '') : '';
            $panggilan = isset($headerMap['panggilan']) ? trim($data[$headerMap['panggilan']] ?? '') : '';
            $kelasInput = isset($headerMap['kelas']) ? trim($data[$headerMap['kelas']] ?? '') : '';
            $noHp = isset($headerMap['no_hp']) ? trim($data[$headerMap['no_hp']] ?? '') : '';

            // Skip empty rows
            if (empty($nama)) continue;

            $status = 'valid';
            $message = 'Siap diimport';
            
            // Use flexible kelas matching
            $kelasFound = findKelas($kelasInput, $kelasMapNormalized);
            $kelasId = $kelasFound ? $kelasFound['id'] : null;
            $kelasNama = $kelasFound ? $kelasFound['nama'] : $kelasInput; // Use found name or original input

            if (empty($kelasInput)) {
                $status = 'warning';
                $message = 'Kelas belum diisi';
            } elseif (!$kelasId) {
                $status = 'error';
                $message = "Kelas '$kelasInput' tidak ada di database";
            }

            $previewData[] = [
                'row' => $rowNumber,
                'nama' => $nama,
                'panggilan' => $panggilan,
                'kelas' => $kelasNama,
                'kelas_id' => $kelasId,
                'no_hp' => $noHp,
                'status' => $status,
                'message' => $message
            ];
        }

        // Also send kelas list for dropdown in frontend
        $kelasList = [];
        foreach ($kelasMap as $namaKelas => $id) {
            $kelasList[] = ['id' => $id, 'nama_kelas' => $namaKelas];
        }

        $response['success'] = true;
        $response['data'] = $previewData;
        $response['kelas_list'] = $kelasList;

    } elseif ($action === 'save') {
        // SAVE MODE
        // Expecting JSON payload in 'data'
        $json = $_POST['data'] ?? '';
        $students = json_decode($json, true);

        if (!$students || !is_array($students)) {
            throw new Exception('Data tidak valid');
        }

        $defaultPassword = 'siswa123';
        $successCount = 0;
        $failCount = 0;
        $errors = [];

        $conn->begin_transaction();

        foreach ($students as $s) {
            // Only process valid marked items
            if ($s['status'] !== 'valid') continue;

            $nama = $conn->real_escape_string($s['nama']);
            $panggilan = $conn->real_escape_string($s['panggilan']);
            $noHp = $conn->real_escape_string($s['no_hp']);
            $kelasId = intval($s['kelas_id']);

            if (empty($panggilan)) {
                $parts = explode(' ', $nama);
                $panggilan = $parts[0];
            }

            // Generate username
            $cleanName = preg_replace('/[^a-z0-9]/', '', strtolower($panggilan));
            $username = $cleanName . rand(100, 999);
            
            $isUnique = false;
            $maxTries = 10;
            while (!$isUnique && $maxTries > 0) {
                $check = $conn->query("SELECT id FROM siswa WHERE username = '$username'");
                if ($check->num_rows == 0) {
                    $isUnique = true;
                } else {
                    $username = $cleanName . rand(100, 999);
                    $maxTries--;
                }
            }

            if (!$isUnique) {
                 $failCount++;
                 $errors[] = "Gagal generate username untuk $nama";
                 continue;
            }

            $stmt = $conn->prepare("INSERT INTO siswa (nama, nama_panggilan, kelas_id, username, password, no_telepon_ortu) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->bind_param("ssisss", $nama, $panggilan, $kelasId, $username, $defaultPassword, $noHp);

            if ($stmt->execute()) {
                $successCount++;
            } else {
                $failCount++;
                $errors[] = "$nama: " . $stmt->error;
            }
        }

        $conn->commit();

        $response['success'] = true;
        $response['message'] = "Berhasil disimpan: $successCount siswa";
        $response['details'] = [
            'success_count' => $successCount,
            'fail_count' => $failCount,
            'errors' => $errors
        ];

    } else {
        throw new Exception('Action tidak valid');
    }

} catch (Exception $e) {
    if (isset($conn)) $conn->rollback();
    $response['success'] = false;
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
?>
