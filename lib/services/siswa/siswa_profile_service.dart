import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hasil dari operasi update profile
class ProfileUpdateResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? updatedData;

  ProfileUpdateResult({
    required this.success,
    required this.message,
    this.updatedData,
  });
}

/// Service untuk menangani update profile siswa
class SiswaProfileService {
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/siswa';

  /// Singleton instance
  static final SiswaProfileService _instance = SiswaProfileService._internal();
  factory SiswaProfileService() => _instance;
  SiswaProfileService._internal();

  /// Update profile siswa
  /// [siswaId] - ID siswa yang akan diupdate
  /// [nama] - Nama lengkap baru
  /// [namaPanggilan] - Nama panggilan baru (opsional)
  /// [password] - Password baru (opsional, jika dikosongkan tidak akan diupdate)
  Future<ProfileUpdateResult> updateProfile({
    required int siswaId,
    required String nama,
    String? namaPanggilan,
    String? password,
  }) async {
    try {
      final body = {
        'siswa_id': siswaId,
        'nama': nama,
        'nama_panggilan': namaPanggilan ?? '',
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // Debug: Print response details
      print('Profile update response status: ${response.statusCode}');
      print('Profile update response body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        return ProfileUpdateResult(
          success: false,
          message: 'Server mengembalikan response kosong. Cek PHP error log.',
        );
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ProfileUpdateResult(
          success: true,
          message: responseData['message'] ?? 'Profil berhasil diperbarui',
          updatedData: responseData['data'],
        );
      } else {
        return ProfileUpdateResult(
          success: false,
          message: responseData['message'] ?? 'Gagal memperbarui profil',
        );
      }
    } catch (e) {
      // Debug: Print actual error
      print('Profile update error: $e');
      return ProfileUpdateResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }
}
