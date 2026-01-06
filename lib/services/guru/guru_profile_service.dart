import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';

class GuruProfileResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  GuruProfileResult({required this.success, required this.message, this.data});
}

class GuruProfileService {
  // Base URL
  static const String _baseUrl = 'https://soulhbc.com/penjemputan/service';

  /// Update profil guru (nama, no_telepon, password opsional)
  Future<GuruProfileResult> updateProfile({
    required int id,
    required String nama,
    required String noTelepon,
    String? password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/guru/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'nama': nama,
          'no_telepon': noTelepon,
          if (password != null && password.isNotEmpty) 'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local user data if successful
        final updatedData = data['data'];
        if (updatedData != null) {
          final currentUser = AuthService().currentUser;
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(nama: updatedData['nama']);
            // Kita tidak menyimpan no_telepon di UserModel saat ini, tapi jika perlu bisa ditambahkan nanti
            await AuthService().updateUser(updatedUser);
          }
        }

        return GuruProfileResult(
          success: true,
          message: data['message'] ?? 'Profil berhasil diperbarui',
          data: data['data'],
        );
      } else {
        return GuruProfileResult(
          success: false,
          message: data['message'] ?? 'Gagal memperbarui profil',
        );
      }
    } catch (e) {
      return GuruProfileResult(
        success: false,
        message: 'Terjadi kesalahan koneksi: $e',
      );
    }
  }

  /// Upload foto profil guru
  Future<GuruProfileResult> uploadPhoto(int userId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/guru_piket/upload_foto.php'),
      );

      request.fields['user_id'] = userId.toString();
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final fotoUrl = data['foto_url'];

        // Update local user data
        if (fotoUrl != null) {
          // Construct full URL if returned path is relative
          // Note: Backend returns relative path like "uploads/guru_piket/..."
          // But AuthService expects full URL usually?
          // Let's check how AuthService handles it.
          // Usually we store full URL or handle base URL in UI.
          // Let's assume we store the full URL or consistent path.

          // Based on siswa_photo_service, it just calls updateAvatarUrl.
          // Let's create a full URL if needed or just pass what we got.
          // For now let's pass what we got, assuming UI handles it or its a full URL.
          // Wait, backend upload_foto.php returns "uploads/guru_piket/filename.jpg"
          // We need to prepend domain if we want full URL.

          String fullUrl = 'https://soulhbc.com/penjemputan/$fotoUrl';
          await AuthService().updateUserFoto(fullUrl);
        }

        return GuruProfileResult(
          success: true,
          message: data['message'] ?? 'Foto berhasil diupload',
          data: {'foto_url': fotoUrl},
        );
      } else {
        return GuruProfileResult(
          success: false,
          message: data['message'] ?? 'Gagal upload foto',
        );
      }
    } catch (e) {
      return GuruProfileResult(
        success: false,
        message: 'Terjadi kesalahan koneksi: $e',
      );
    }
  }

  /// Delete foto user
  // (Optional, if we want to allow deleting photo)
}
