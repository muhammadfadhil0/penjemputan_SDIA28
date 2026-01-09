import 'dart:convert';
import 'package:http/http.dart' as http;

class EmergencyStatus {
  final bool active;
  final String? activatedBy;
  final int? activatedById;
  final String? activatedByRole;
  final int? kelasId;
  final String? kelasName;
  final String? activatedAt;
  final String? updatedAt;

  const EmergencyStatus({
    required this.active,
    this.activatedBy,
    this.activatedById,
    this.activatedByRole,
    this.kelasId,
    this.kelasName,
    this.activatedAt,
    this.updatedAt,
  });

  factory EmergencyStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EmergencyStatus(active: false);
    }

    return EmergencyStatus(
      active: json['active'] == true,
      activatedBy: json['activated_by'] as String?,
      activatedById: json['activated_by_id'] as int?,
      activatedByRole: json['activated_by_role'] as String?,
      kelasId: json['kelas_id'] as int?,
      kelasName: json['kelas_name'] as String?,
      activatedAt: json['activated_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  EmergencyStatus copyWith({
    bool? active,
    String? activatedBy,
    int? activatedById,
    String? activatedByRole,
    int? kelasId,
    String? kelasName,
    String? activatedAt,
    String? updatedAt,
  }) {
    return EmergencyStatus(
      active: active ?? this.active,
      activatedBy: activatedBy ?? this.activatedBy,
      activatedById: activatedById ?? this.activatedById,
      activatedByRole: activatedByRole ?? this.activatedByRole,
      kelasId: kelasId ?? this.kelasId,
      kelasName: kelasName ?? this.kelasName,
      activatedAt: activatedAt ?? this.activatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmergencyService {
  static const String _endpoint =
      'https://soulhbc.com/penjemputan/service/config/emergency_mode.php';

  Future<EmergencyStatus> getStatus() async {
    try {
      final response = await http.get(Uri.parse(_endpoint)).timeout(
        const Duration(seconds: 10),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return EmergencyStatus.fromJson(data['data'] as Map<String, dynamic>?);
      }
    } catch (_) {}
    return const EmergencyStatus(active: false);
  }

  Future<EmergencyStatus> activate({
    required String activatedBy,
    int? activatedById,
    String? activatedByRole,
    int? kelasId,
    String? kelasName,
  }) async {
    final payload = {
      'action': 'activate',
      'activated_by': activatedBy,
      if (activatedById != null) 'activated_by_id': activatedById,
      if (activatedByRole != null) 'activated_by_role': activatedByRole,
      if (kelasId != null) 'kelas_id': kelasId,
      if (kelasName != null) 'kelas_name': kelasName,
    };

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return EmergencyStatus.fromJson(data['data'] as Map<String, dynamic>?);
      }
    } catch (_) {}

    return const EmergencyStatus(active: false);
  }

  Future<EmergencyStatus> deactivate() async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'deactivate'}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return EmergencyStatus.fromJson(data['data'] as Map<String, dynamic>?);
      }
    } catch (_) {}

    return const EmergencyStatus(active: false);
  }
}
