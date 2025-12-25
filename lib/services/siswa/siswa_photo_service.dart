import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import '../auth/multi_account_service.dart';

/// Response wrapper untuk hasil upload foto
class PhotoUploadResult {
  final bool success;
  final String message;
  final String? fotoUrl;

  PhotoUploadResult({
    required this.success,
    required this.message,
    this.fotoUrl,
  });
}

/// Service untuk menangani upload/delete foto profil siswa
class SiswaPhotoService {
  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/database';

  /// Upload foto profil siswa
  Future<PhotoUploadResult> uploadPhoto(int siswaId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload_foto_siswa.php'),
      );

      // Tambahkan siswa_id
      request.fields['siswa_id'] = siswaId.toString();

      // Tambahkan file foto
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );

      // Kirim request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final fotoUrl = responseData['data']['foto_url'] as String?;

        // Update foto di auth service
        if (fotoUrl != null) {
          await AuthService().updateUserFoto(fotoUrl);

          // Sync dengan multi-account service
          final authUser = AuthService().currentUser;
          if (authUser != null) {
            await MultiAccountService().updateAccount(authUser);
          }
        }

        return PhotoUploadResult(
          success: true,
          message: responseData['message'] ?? 'Foto berhasil diupload!',
          fotoUrl: fotoUrl,
        );
      } else {
        return PhotoUploadResult(
          success: false,
          message: responseData['message'] ?? 'Gagal mengupload foto.',
        );
      }
    } catch (e) {
      return PhotoUploadResult(
        success: false,
        message: 'Tidak dapat terhubung ke server.',
      );
    }
  }

  /// Hapus foto profil siswa
  Future<PhotoUploadResult> deletePhoto(int siswaId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_foto_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'siswa_id': siswaId}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update foto di auth service (set ke null)
        await AuthService().updateUserFoto(null);

        // Sync dengan multi-account service
        final authUser = AuthService().currentUser;
        if (authUser != null) {
          await MultiAccountService().updateAccount(authUser);
        }

        return PhotoUploadResult(
          success: true,
          message: responseData['message'] ?? 'Foto berhasil dihapus!',
        );
      } else {
        return PhotoUploadResult(
          success: false,
          message: responseData['message'] ?? 'Gagal menghapus foto.',
        );
      }
    } catch (e) {
      return PhotoUploadResult(
        success: false,
        message: 'Tidak dapat terhubung ke server.',
      );
    }
  }

  /// Update foto profil dengan avatar URL dari CDN
  Future<PhotoUploadResult> updateAvatarUrl(
    int siswaId,
    String avatarUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_foto_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'siswa_id': siswaId, 'foto_url': avatarUrl}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update foto di auth service
        await AuthService().updateUserFoto(avatarUrl);

        // Sync dengan multi-account service
        final authUser = AuthService().currentUser;
        if (authUser != null) {
          await MultiAccountService().updateAccount(authUser);
        }

        return PhotoUploadResult(
          success: true,
          message: responseData['message'] ?? 'Avatar berhasil diperbarui!',
          fotoUrl: avatarUrl,
        );
      } else {
        return PhotoUploadResult(
          success: false,
          message: responseData['message'] ?? 'Gagal memperbarui avatar.',
        );
      }
    } catch (e) {
      return PhotoUploadResult(
        success: false,
        message: 'Tidak dapat terhubung ke server.',
      );
    }
  }
}
