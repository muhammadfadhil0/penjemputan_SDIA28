import 'dart:convert';
import 'package:http/http.dart' as http;
import 'jadwal_model.dart';

/// Result wrapper untuk hasil pengambilan jadwal
class JadwalResult {
  final bool success;
  final String message;
  final JadwalKelas? jadwal;

  JadwalResult({required this.success, required this.message, this.jadwal});
}

/// Service untuk mengambil data jadwal dari backend
class JadwalService {
  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/jadwal';

  /// Singleton instance
  static final JadwalService _instance = JadwalService._internal();
  factory JadwalService() => _instance;
  JadwalService._internal();

  /// Cache untuk data jadwal (kelas_id -> JadwalKelas)
  static final Map<int, JadwalKelas> _cache = {};

  /// Mendapatkan jadwal dari cache
  JadwalKelas? getCachedJadwal(int kelasId) => _cache[kelasId];

  /// Menyimpan jadwal ke cache
  void cacheJadwal(int kelasId, JadwalKelas jadwal) {
    _cache[kelasId] = jadwal;
  }

  /// Menghapus cache untuk kelas tertentu
  void clearCache([int? kelasId]) {
    if (kelasId != null) {
      _cache.remove(kelasId);
    } else {
      _cache.clear();
    }
  }

  /// Cek apakah ada cache untuk kelas tertentu
  bool hasCache(int kelasId) => _cache.containsKey(kelasId);

  /// Mengambil jadwal berdasarkan kelas_id
  Future<JadwalResult> getJadwalByKelas(int kelasId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_jadwal_siswa.php?kelas_id=$kelasId'))
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        if (data != null) {
          return JadwalResult(
            success: true,
            message: responseData['message'] ?? 'Jadwal berhasil dimuat',
            jadwal: JadwalKelas.fromJson(data),
          );
        } else {
          return JadwalResult(
            success: false,
            message: 'Data jadwal tidak ditemukan',
          );
        }
      } else {
        return JadwalResult(
          success: false,
          message: responseData['message'] ?? 'Gagal memuat jadwal',
        );
      }
    } catch (e) {
      return JadwalResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Mengambil jadwal berdasarkan tingkat kelas (untuk ambil jadwal semua kelas di tingkat tersebut)
  Future<JadwalResult> getJadwalByTingkat(int tingkat) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_jadwal.php?tingkat=$tingkat'))
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final dataList = responseData['data'] as List?;
        if (dataList != null && dataList.isNotEmpty) {
          // Ambil jadwal kelas pertama dari tingkat tersebut
          return JadwalResult(
            success: true,
            message: responseData['message'] ?? 'Jadwal berhasil dimuat',
            jadwal: JadwalKelas.fromJson(dataList.first),
          );
        } else {
          return JadwalResult(
            success: false,
            message: 'Data jadwal tidak ditemukan',
          );
        }
      } else {
        return JadwalResult(
          success: false,
          message: responseData['message'] ?? 'Gagal memuat jadwal',
        );
      }
    } catch (e) {
      return JadwalResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }
}
