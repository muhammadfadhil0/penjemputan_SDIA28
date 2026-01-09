<?php
/**
 * API Endpoint: Emergency Mode
 *
 * GET  -> Mengambil status emergency mode.
 * POST -> Mengaktifkan / menonaktifkan emergency mode.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

date_default_timezone_set('Asia/Jakarta');

require_once 'koneksi.php';
require_once '../lib/emergency.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $status = get_emergency_status($conn);

    echo json_encode([
        'success' => true,
        'data' => $status,
        'message' => $status['active']
            ? 'Emergency mode aktif'
            : 'Emergency mode non-aktif'
    ]);
    exit();
}

if ($method !== 'POST') {
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use GET or POST.'
    ]);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true) ?? [];
$action = isset($input['action']) ? strtolower(trim($input['action'])) : 'activate';

if (!in_array($action, ['activate', 'deactivate'], true)) {
    echo json_encode([
        'success' => false,
        'message' => 'Action tidak valid. Gunakan: activate | deactivate'
    ]);
    exit();
}

if ($action === 'activate') {
    $activatedBy = trim($input['activated_by'] ?? '');
    if ($activatedBy === '') {
        echo json_encode([
            'success' => false,
            'message' => 'activated_by diperlukan untuk mengaktifkan mode darurat'
        ]);
        exit();
    }

    $payload = [
        'active' => true,
        'activated_by' => $activatedBy,
        'activated_by_id' => isset($input['activated_by_id']) ? intval($input['activated_by_id']) : null,
        'activated_by_role' => isset($input['activated_by_role']) ? trim($input['activated_by_role']) : null,
        'kelas_id' => isset($input['kelas_id']) ? intval($input['kelas_id']) : null,
        'kelas_name' => isset($input['kelas_name']) ? trim($input['kelas_name']) : null,
        'activated_at' => date('Y-m-d H:i:s'),
        'deactivated_at' => null,
    ];

    $saved = save_emergency_status($conn, $payload, 'Status emergency mode (aktif)');
    echo json_encode([
        'success' => (bool)$saved,
        'data' => $payload,
        'message' => $saved ? 'Emergency mode diaktifkan' : 'Gagal menyimpan status emergency mode'
    ]);
    exit();
}

// Deactivate branch
$current = get_emergency_status($conn);
$payload = array_merge($current, [
    'active' => false,
    'deactivated_at' => date('Y-m-d H:i:s'),
]);

$saved = save_emergency_status($conn, $payload, 'Status emergency mode (non-aktif)');

echo json_encode([
    'success' => (bool)$saved,
    'data' => $payload,
    'message' => $saved ? 'Emergency mode dinonaktifkan' : 'Gagal memperbarui status emergency mode'
]);

?>
