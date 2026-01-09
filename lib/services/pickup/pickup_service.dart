import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result wrapper untuk hasil permintaan jemput
class PickupResult {
  final bool success;
  final String message;
  final int? nomorAntrian;
  final int? requestId;
  final bool emergencyActive;
  final Map<String, dynamic>? emergencyData;

  PickupResult({
    required this.success,
    required this.message,
    this.nomorAntrian,
    this.requestId,
    this.emergencyActive = false,
    this.emergencyData,
  });
}

/// Status pickup siswa saat ini
class PickupStatus {
  final bool hasActiveRequest;
  final String? status; // 'menunggu', 'dipanggil', null
  final int? nomorAntrian;
  final bool inCooldown;
  final int cooldownRemainingSeconds;

  PickupStatus({
    required this.hasActiveRequest,
    this.status,
    this.nomorAntrian,
    this.inCooldown = false,
    this.cooldownRemainingSeconds = 0,
  });

  factory PickupStatus.fromJson(Map<String, dynamic> json) {
    return PickupStatus(
      hasActiveRequest: json['has_active_request'] ?? false,
      status: json['status'],
      nomorAntrian: json['nomor_antrian'],
      inCooldown: json['in_cooldown'] ?? false,
      cooldownRemainingSeconds: json['cooldown_remaining_seconds'] ?? 0,
    );
  }

  /// Status idle - tidak ada request aktif dan tidak dalam cooldown
  bool get isIdle => !hasActiveRequest && !inCooldown;

  /// Status queued - dalam antrean menunggu dipanggil
  bool get isQueued => hasActiveRequest && status == 'menunggu';

  /// Status called - sudah dipanggil, menunggu dijemput
  bool get isCalled => hasActiveRequest && status == 'dipanggil';
}

/// Service untuk menangani permintaan penjemputan siswa
class PickupService {
  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/pickup';

  /// Singleton instance
  static final PickupService _instance = PickupService._internal();
  factory PickupService() => _instance;
  PickupService._internal();

  /// Kirim permintaan jemput ke server
  Future<PickupResult> requestPickup({
    required int siswaId,
    required String penjemput,
    String? penjemputDetail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add_pickup_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'siswa_id': siswaId,
          'penjemput': penjemput,
          'penjemput_detail': penjemputDetail,
        }),
      );

      final responseData = jsonDecode(response.body);
      final emergency = responseData['data']?['emergency_mode'] ?? responseData['emergency_mode'];
      final isEmergencyActive = emergency is Map && (emergency['active'] == true);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return PickupResult(
          success: true,
          message: responseData['message'] ?? 'Permintaan jemput berhasil!',
          nomorAntrian: responseData['data']?['nomor_antrian'],
          requestId: responseData['data']?['request_id'],
          emergencyActive: isEmergencyActive,
          emergencyData: emergency is Map<String, dynamic>
              ? emergency as Map<String, dynamic>
              : null,
        );
      } else {
        return PickupResult(
          success: false,
          message:
              responseData['message'] ?? 'Gagal mengirim permintaan jemput.',
          emergencyActive: isEmergencyActive,
          emergencyData: emergency is Map<String, dynamic>
              ? emergency as Map<String, dynamic>
              : null,
        );
      }
    } catch (e) {
      return PickupResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        emergencyActive: false,
        emergencyData: null,
      );
    }
  }

  /// Cek status pickup siswa saat ini
  Future<PickupStatus?> getPickupStatus(int siswaId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_pickup_status.php?siswa_id=$siswaId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PickupStatus.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
