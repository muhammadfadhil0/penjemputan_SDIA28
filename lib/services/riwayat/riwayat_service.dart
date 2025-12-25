import 'dart:convert';
import 'package:http/http.dart' as http;
import 'riwayat_model.dart';

/// Service untuk mengambil data riwayat penjemputan
class RiwayatService {
  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/riwayat';

  /// Singleton instance
  static final RiwayatService _instance = RiwayatService._internal();
  factory RiwayatService() => _instance;
  RiwayatService._internal();

  /// Mengambil riwayat penjemputan untuk siswa tertentu
  ///
  /// [siswaId] - ID siswa (required)
  /// [tanggal] - Filter berdasarkan tanggal (optional)
  /// [limit] - Jumlah data yang diambil (default: 50)
  Future<RiwayatResult> getRiwayatSiswa({
    required int siswaId,
    DateTime? tanggal,
    int limit = 50,
  }) async {
    try {
      // Build request body
      final Map<String, dynamic> body = {'siswa_id': siswaId, 'limit': limit};

      // Add date filter if provided
      if (tanggal != null) {
        body['tanggal'] = _formatDate(tanggal);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/get_riwayat_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return RiwayatResult.fromJson(responseData);
      } else {
        return RiwayatResult(
          success: false,
          message: 'Gagal mengambil data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RiwayatResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Helper untuk format tanggal ke YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
