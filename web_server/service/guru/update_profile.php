<?php
/**
 * Update Profile Guru - SDIA 28 Sistem Penjemputan
 * Endpoint khusus untuk aplikasi Flutter agar bisa update nama/no_hp tanpa wajib ganti password
 */
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method tidak diizinkan."]);
    exit();
}

require_once '../../config/koneksi.php';

$data = json_decode(file_get_contents("php://input"), true);
$id = (int)($data['id'] ?? 0);
$nama = trim($data['nama'] ?? '');
$no_telepon = trim($data['no_telepon'] ?? '');
$password = trim($data['password'] ?? ''); // Optional

if ($id <= 0 || empty($nama)) {
    echo json_encode(["success" => false, "message" => "Data nama tidak boleh kosong."]);
    exit();
}

// Build query dynamically
$query = "UPDATE users SET nama=?, no_telepon=?";
$params = [$nama, $no_telepon];
$types = "ss";

// Add password update only if provided
if (!empty($password)) {
    $query .= ", password=?";
    $params[] = $password;
    $types .= "s";
}

$query .= " WHERE id=?";
$params[] = $id;
$types .= "i";

$stmt = mysqli_prepare($conn, $query);

// Bind params dynamically
mysqli_stmt_bind_param($stmt, $types, ...$params);

if (mysqli_stmt_execute($stmt)) {
    // Check if ID exists
    if (mysqli_affected_rows($conn) >= 0) {
        // Fetch updated data to return
        $select = mysqli_prepare($conn, "SELECT id, username, nama, no_telepon FROM users WHERE id = ?");
        mysqli_stmt_bind_param($select, "i", $id);
        mysqli_stmt_execute($select);
        $result = mysqli_stmt_get_result($select);
        $user = mysqli_fetch_assoc($result);
        
        echo json_encode([
            "success" => true, 
            "message" => "Profil berhasil diperbarui!",
            "data" => $user
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "ID guru tidak ditemukan."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Gagal mengupdate data: " . mysqli_error($conn)]);
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>
