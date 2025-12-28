<?php
/**
 * API Endpoint: Update Application Settings
 * 
 * Memperbarui pengaturan aplikasi di database.
 * Menerima JSON dengan key dan value yang ingin diupdate.
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

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use POST.'
    ]);
    exit();
}

// Include database connection
require_once 'koneksi.php';

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
if (!isset($input['key']) || !isset($input['value'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Data tidak lengkap. Diperlukan: key, value'
    ]);
    exit();
}

$key = mysqli_real_escape_string($conn, $input['key']);
$value = mysqli_real_escape_string($conn, $input['value']);

// Validate cooldown_minutes specifically
if ($key === 'cooldown_minutes') {
    $minutes = intval($value);
    if ($minutes < 1 || $minutes > 60) {
        echo json_encode([
            'success' => false,
            'message' => 'Nilai cooldown harus antara 1-60 menit'
        ]);
        exit();
    }
    $value = strval($minutes);
}

// Check if key exists
$check_query = "SELECT id FROM pengaturan_aplikasi WHERE key_name = '$key'";
$check_result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($check_result) > 0) {
    // Update existing setting
    $update_query = "UPDATE pengaturan_aplikasi SET value = '$value', updated_at = NOW() WHERE key_name = '$key'";
    
    if (mysqli_query($conn, $update_query)) {
        echo json_encode([
            'success' => true,
            'message' => 'Pengaturan berhasil diperbarui',
            'data' => [
                'key' => $key,
                'value' => $value
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal memperbarui pengaturan: ' . mysqli_error($conn)
        ]);
    }
} else {
    // Insert new setting
    $description = isset($input['description']) ? mysqli_real_escape_string($conn, $input['description']) : null;
    $desc_sql = $description ? "'$description'" : "NULL";
    
    $insert_query = "INSERT INTO pengaturan_aplikasi (key_name, value, description) VALUES ('$key', '$value', $desc_sql)";
    
    if (mysqli_query($conn, $insert_query)) {
        echo json_encode([
            'success' => true,
            'message' => 'Pengaturan berhasil ditambahkan',
            'data' => [
                'key' => $key,
                'value' => $value
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Gagal menambahkan pengaturan: ' . mysqli_error($conn)
        ]);
    }
}

mysqli_close($conn);
?>
