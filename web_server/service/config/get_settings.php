<?php
/**
 * API Endpoint: Get Application Settings
 * 
 * Mengambil pengaturan aplikasi dari database.
 * Bisa mengambil semua pengaturan atau berdasarkan key tertentu.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection
require_once 'koneksi.php';

// Get specific key if provided
$key = isset($_GET['key']) ? mysqli_real_escape_string($conn, $_GET['key']) : null;

if ($key) {
    // Get specific setting
    $query = "SELECT key_name, value, description, updated_at FROM pengaturan_aplikasi WHERE key_name = '$key'";
    $result = mysqli_query($conn, $query);
    
    if (mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        echo json_encode([
            'success' => true,
            'data' => $row
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Pengaturan tidak ditemukan'
        ]);
    }
} else {
    // Get all settings
    $query = "SELECT key_name, value, description, updated_at FROM pengaturan_aplikasi ORDER BY key_name";
    $result = mysqli_query($conn, $query);
    
    $settings = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $settings[$row['key_name']] = [
            'value' => $row['value'],
            'description' => $row['description'],
            'updated_at' => $row['updated_at']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $settings
    ]);
}

mysqli_close($conn);
?>
