<?php
/**
 * Import Excel Guru Piket - SDIA 28 Sistem Penjemputan
 */
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

require_once '../config/koneksi.php';
require_once '../lib/SimpleXLSX.php';

$action = $_POST['action'] ?? '';

if ($action === 'preview') {
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(["success" => false, "message" => "File tidak ditemukan atau error upload."]);
        exit();
    }
    
    $xlsx = SimpleXLSX::parse($_FILES['file']['tmp_name']);
    if (!$xlsx) {
        echo json_encode(["success" => false, "message" => "Gagal membaca file Excel: " . SimpleXLSX::parseError()]);
        exit();
    }
    
    $rows = $xlsx->rows();
    $data = [];
    $existingUsernames = [];
    
    // Get existing usernames
    $result = mysqli_query($conn, "SELECT username FROM users");
    while ($row = mysqli_fetch_assoc($result)) {
        $existingUsernames[] = strtolower($row['username']);
    }
    
    $hasNo = false;
    if (count($rows) > 0) {
        $firstRow = array_map('strtolower', array_map('trim', $rows[0]));
        $hasNo = in_array('no', $firstRow) || is_numeric(trim($rows[0][0] ?? ''));
    }
    
    $startRow = 1; // Skip header
    foreach ($rows as $i => $row) {
        if ($i < $startRow) continue;
        if (count(array_filter($row)) === 0) continue;
        
        $offset = $hasNo ? 1 : 0;
        $username = trim($row[$offset] ?? '');
        $password = trim($row[$offset + 1] ?? '');
        $nama = trim($row[$offset + 2] ?? '');
        $no_telepon = trim($row[$offset + 3] ?? '');
        
        $status = 'valid';
        $message = 'Siap diimport';
        
        if (empty($username)) { $status = 'error'; $message = 'Username kosong'; }
        elseif (empty($password)) { $status = 'error'; $message = 'Password kosong'; }
        elseif (empty($nama)) { $status = 'error'; $message = 'Nama kosong'; }
        elseif (in_array(strtolower($username), $existingUsernames)) { $status = 'warning'; $message = 'Username sudah ada'; }
        
        $data[] = [
            'row' => $i + 1,
            'username' => $username,
            'password' => $password,
            'nama' => $nama,
            'no_telepon' => $no_telepon,
            'status' => $status,
            'message' => $message
        ];
    }
    
    echo json_encode(["success" => true, "data" => $data]);
    
} elseif ($action === 'save') {
    $jsonData = $_POST['data'] ?? '';
    $items = json_decode($jsonData, true);
    
    if (!$items || !is_array($items)) {
        echo json_encode(["success" => false, "message" => "Data tidak valid."]);
        exit();
    }
    
    $success = 0;
    $failed = 0;
    
    $stmt = mysqli_prepare($conn, "INSERT INTO users (username, password, role, nama, no_telepon) VALUES (?, ?, 'guru', ?, ?)");
    
    foreach ($items as $item) {
        if ($item['status'] !== 'valid') continue;
        
        mysqli_stmt_bind_param($stmt, "ssss", $item['username'], $item['password'], $item['nama'], $item['no_telepon']);
        if (mysqli_stmt_execute($stmt)) {
            $success++;
        } else {
            $failed++;
        }
    }
    
    mysqli_stmt_close($stmt);
    echo json_encode(["success" => true, "message" => "Berhasil import $success guru piket. Gagal: $failed"]);
    
} else {
    echo json_encode(["success" => false, "message" => "Action tidak valid."]);
}

mysqli_close($conn);
?>
