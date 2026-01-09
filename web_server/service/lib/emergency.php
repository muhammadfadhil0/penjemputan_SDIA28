<?php
/**
 * Helper functions for Emergency Mode status storage.
 *
 * Data disimpan pada tabel pengaturan_aplikasi dengan key `emergency_mode`
 * dalam bentuk JSON. Struktur default:
 * {
 *   "active": bool,
 *   "activated_by": string|null,
 *   "activated_by_id": int|null,
 *   "activated_by_role": string|null,
 *   "kelas_id": int|null,
 *   "kelas_name": string|null,
 *   "activated_at": string|null,
 *   "deactivated_at": string|null
 * }
 */

if (!function_exists('get_emergency_status')) {
    function get_emergency_status($conn)
    {
        $default = [
            'active' => false,
            'activated_by' => null,
            'activated_by_id' => null,
            'activated_by_role' => null,
            'kelas_id' => null,
            'kelas_name' => null,
            'activated_at' => null,
            'deactivated_at' => null,
        ];

        $query = "SELECT value, updated_at FROM pengaturan_aplikasi WHERE key_name = 'emergency_mode' LIMIT 1";
        $result = mysqli_query($conn, $query);

        if ($result && mysqli_num_rows($result) > 0) {
            $row = mysqli_fetch_assoc($result);
            $value = json_decode($row['value'], true);

            if (is_array($value)) {
                return array_merge($default, $value, [
                    'updated_at' => $row['updated_at'] ?? null,
                ]);
            }
        }

        return $default;
    }
}

if (!function_exists('save_emergency_status')) {
    function save_emergency_status($conn, array $payload, $description = 'Status emergency mode')
    {
        $json = json_encode($payload);
        $safeJson = mysqli_real_escape_string($conn, $json);
        $safeDesc = mysqli_real_escape_string($conn, $description);

        $check = "SELECT id FROM pengaturan_aplikasi WHERE key_name = 'emergency_mode' LIMIT 1";
        $exists = mysqli_query($conn, $check);

        if ($exists && mysqli_num_rows($exists) > 0) {
            $update = "UPDATE pengaturan_aplikasi SET value = '$safeJson', description = '$safeDesc', updated_at = NOW() WHERE key_name = 'emergency_mode'";
            return mysqli_query($conn, $update);
        }

        $insert = "INSERT INTO pengaturan_aplikasi (key_name, value, description, updated_at) VALUES ('emergency_mode', '$safeJson', '$safeDesc', NOW())";
        return mysqli_query($conn, $insert);
    }
}

?>
