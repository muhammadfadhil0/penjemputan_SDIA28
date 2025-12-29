<?php
/**
 * Upload Foto Guru Piket - SDIA 28 Sistem Penjemputan
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Check if file was uploaded
if (!isset($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(['success' => false, 'message' => 'No file uploaded or upload error']);
    exit;
}

$file = $_FILES['foto'];
$userId = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if ($userId <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid user ID']);
    exit;
}

// Validate file type
$allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
$fileType = mime_content_type($file['tmp_name']);

if (!in_array($fileType, $allowedTypes)) {
    echo json_encode(['success' => false, 'message' => 'Only JPG and PNG files are allowed']);
    exit;
}

// Validate file size (max 5MB)
$maxSize = 5 * 1024 * 1024;
if ($file['size'] > $maxSize) {
    echo json_encode(['success' => false, 'message' => 'Ukuran file maksimal 5MB']);
    exit;
}

// Create upload directory if not exists
$uploadDir = '../../uploads/guru_piket/';
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Generate unique filename
$extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$filename = 'guru_' . $userId . '_' . time() . '.' . $extension;
$targetPath = $uploadDir . $filename;

// Delete old photo if exists
$stmt = mysqli_prepare($conn, "SELECT foto FROM users WHERE id = ?");
mysqli_stmt_bind_param($stmt, "i", $userId);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
$user = mysqli_fetch_assoc($result);
mysqli_stmt_close($stmt);

if ($user && !empty($user['foto'])) {
    $oldPhotoPath = '../../' . $user['foto'];
    if (file_exists($oldPhotoPath)) {
        @unlink($oldPhotoPath);
    }
}

// Move uploaded file
if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    echo json_encode(['success' => false, 'message' => 'Failed to save file']);
    mysqli_close($conn);
    exit;
}

// Update database with photo path
$photoPath = 'uploads/guru_piket/' . $filename;

$stmt = mysqli_prepare($conn, "UPDATE users SET foto = ? WHERE id = ?");
mysqli_stmt_bind_param($stmt, "si", $photoPath, $userId);

if (mysqli_stmt_execute($stmt)) {
    echo json_encode([
        'success' => true,
        'message' => 'Photo uploaded successfully',
        'foto_url' => $photoPath
    ]);
} else {
    // Delete uploaded file if database update fails
    if (file_exists($targetPath)) {
        @unlink($targetPath);
    }
    echo json_encode(['success' => false, 'message' => 'Database error: ' . mysqli_error($conn)]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
