import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'kelas_models.dart';

/// Service untuk menangani API class view
class KelasService {
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/class_view';

  /// Fetch students dengan status penjemputan hari ini
  Future<KelasStudentsResponse> getStudents(int kelasId) async {
    try {
      final url = '$_baseUrl/get_students.php?kelas_id=$kelasId';
      debugPrint('[KelasService] Fetching students: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return KelasStudentsResponse.fromJson(json);
      } else {
        debugPrint(
          '[KelasService] Error: ${response.statusCode} - ${response.body}',
        );
        return KelasStudentsResponse(
          success: false,
          message: 'Gagal mengambil data siswa (${response.statusCode})',
          students: [],
        );
      }
    } catch (e) {
      debugPrint('[KelasService] Exception: $e');
      return KelasStudentsResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
        students: [],
      );
    }
  }

  /// Fetch riwayat penjemputan (hari ini atau tanggal tertentu)
  Future<KelasHistoryResponse> getHistory(
    int kelasId, {
    int limit = 30,
    DateTime? tanggal,
  }) async {
    try {
      String url =
          '$_baseUrl/get_class_history.php?kelas_id=$kelasId&limit=$limit';

      // Tambahkan filter tanggal jika ada
      if (tanggal != null) {
        final formattedDate =
            '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
        url += '&tanggal=$formattedDate';
      }

      debugPrint('[KelasService] Fetching history: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return KelasHistoryResponse.fromJson(json);
      } else {
        debugPrint(
          '[KelasService] Error: ${response.statusCode} - ${response.body}',
        );
        return KelasHistoryResponse(
          success: false,
          message: 'Gagal mengambil riwayat (${response.statusCode})',
          count: 0,
          data: [],
        );
      }
    } catch (e) {
      debugPrint('[KelasService] Exception: $e');
      return KelasHistoryResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
        count: 0,
        data: [],
      );
    }
  }
}
