import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model untuk guru yang sedang aktif bertugas
class ActiveTeacher {
  final int id;
  final String nama;
  final String role;

  ActiveTeacher({required this.id, required this.nama, required this.role});

  factory ActiveTeacher.fromJson(Map<String, dynamic> json) {
    return ActiveTeacher(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

/// Service untuk mendapatkan informasi guru yang sedang bertugas
class TeacherService {
  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/auth_login';

  /// Singleton instance
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

  /// Mendapatkan guru yang sedang aktif bertugas di web dashboard
  Future<ActiveTeacher?> getActiveTeacher() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_active_teacher.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['has_active_teacher'] == true) {
          return ActiveTeacher.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
