<?php
/**
 * API Endpoint: Get Kelas Rombel
 * 
 * Fetch all classes grouped by tingkat (grade level).
 * Used for dynamic class selection in jadwal.html
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once '../config/koneksi.php';

try {
    $sql = "SELECT id, nama_kelas, tingkat FROM kelas ORDER BY tingkat ASC, nama_kelas ASC";
    $result = $conn->query($sql);
    
    $groupedClasses = [];
    
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $tingkat = $row['tingkat'];
            $fullClassName = $row['nama_kelas'];
            
            // Extract rombel name (e.g., "Kelas 1 Abu Bakar" -> "Abu Bakar")
            // Assuming format "Kelas X [Name]"
            $rombelName = $fullClassName;
            $prefix = "Kelas " . $tingkat . " ";
            
            if (strpos($fullClassName, $prefix) === 0) {
                $rombelName = substr($fullClassName, strlen($prefix));
            }
            
            if (!isset($groupedClasses[$tingkat])) {
                $groupedClasses[$tingkat] = [];
            }
            
            $groupedClasses[$tingkat][] = [
                'id' => $row['id'],
                'name' => $rombelName, // Short name for button (e.g. "Abu Bakar")
                'full_name' => $fullClassName
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'data' => $groupedClasses
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error fetching data: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
