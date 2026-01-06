import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model untuk data siswa yang bisa dipanggil oleh guru
class StudentForPickup {
  final int id;
  final String nama;
  final String? namaPanggilan;
  final String namaKelas;
  final int kelasId;
  final int tingkat;
  final String? fotoUrl;
  final bool hasActiveRequest;
  final String? currentStatus; // 'menunggu', 'dipanggil', null

  StudentForPickup({
    required this.id,
    required this.nama,
    this.namaPanggilan,
    required this.namaKelas,
    required this.kelasId,
    required this.tingkat,
    this.fotoUrl,
    this.hasActiveRequest = false,
    this.currentStatus,
  });

  factory StudentForPickup.fromJson(Map<String, dynamic> json) {
    return StudentForPickup(
      id: json['id'] as int,
      nama: json['nama'] as String,
      namaPanggilan: json['nama_panggilan'] as String?,
      namaKelas: json['nama_kelas'] as String,
      kelasId: json['kelas_id'] as int,
      tingkat: json['tingkat'] as int,
      fotoUrl: json['foto_url'] as String?,
      hasActiveRequest: json['has_active_request'] ?? false,
      currentStatus: json['current_status'] as String?,
    );
  }

  /// Mendapatkan nama tampilan (nama panggilan atau nama lengkap)
  String get displayName => namaPanggilan ?? nama.split(' ').first;
}

/// Result wrapper untuk hasil pemanggilan siswa oleh guru
class GuruPickupResult {
  final bool success;
  final String message;
  final int? nomorAntrian;
  final int? requestId;

  GuruPickupResult({
    required this.success,
    required this.message,
    this.nomorAntrian,
    this.requestId,
  });
}

/// Model untuk data kelas
class KelasData {
  final int id;
  final String nama;
  final int tingkat;

  KelasData({required this.id, required this.nama, required this.tingkat});

  factory KelasData.fromJson(Map<String, dynamic> json) {
    return KelasData(
      id: json['id'] as int,
      nama: json['nama'] as String,
      tingkat: json['tingkat'] as int,
    );
  }
}

/// Service untuk menangani fitur penjemputan oleh guru
class GuruPickupService {
  // Base URL untuk API backend
  static const String _baseUrl = 'https://soulhbc.com/penjemputan/service/guru';

  /// Singleton instance
  static final GuruPickupService _instance = GuruPickupService._internal();
  factory GuruPickupService() => _instance;
  GuruPickupService._internal();

  /// Ambil daftar semua kelas
  Future<List<KelasData>> getKelasList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_kelas_list.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => KelasData.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kelas list: $e');
      return [];
    }
  }

  /// Cari siswa berdasarkan nama dan/atau kelas
  Future<List<StudentForPickup>> searchStudents({
    String? query,
    int? kelasId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (kelasId != null) {
        queryParams['kelas_id'] = kelasId.toString();
      }

      final uri = Uri.parse(
        '$_baseUrl/search_students.php',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => StudentForPickup.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching students: $e');
      return [];
    }
  }

  /// Panggil siswa untuk penjemputan (oleh guru)
  Future<GuruPickupResult> callStudentForPickup({
    required int siswaId,
    required String calledByGuruName,
    String penjemput = 'guru', // Default penjemput adalah guru
    String? catatan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/call_student.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'siswa_id': siswaId,
          'called_by': calledByGuruName,
          'penjemput': penjemput,
          'catatan': catatan,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return GuruPickupResult(
          success: true,
          message: responseData['message'] ?? 'Siswa berhasil dipanggil!',
          nomorAntrian: responseData['data']?['nomor_antrian'],
          requestId: responseData['data']?['request_id'],
        );
      } else {
        return GuruPickupResult(
          success: false,
          message: responseData['message'] ?? 'Gagal memanggil siswa.',
        );
      }
    } catch (e) {
      return GuruPickupResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Ambil daftar siswa yang bisa dipanggil (belum ada request aktif)
  Future<List<StudentForPickup>> getAvailableStudents({int? kelasId}) async {
    try {
      final queryParams = <String, String>{'available_only': 'true'};
      if (kelasId != null) {
        queryParams['kelas_id'] = kelasId.toString();
      }

      final uri = Uri.parse(
        '$_baseUrl/search_students.php',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => StudentForPickup.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching available students: $e');
      return [];
    }
  }

  /// Tambah siswa baru ke database
  Future<GuruPickupResult> addStudent({
    required String nama,
    String? namaPanggilan,
    required int kelasId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://soulhbc.com/penjemputan/service/database/add_siswa.php',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'nama_panggilan': namaPanggilan ?? '',
          'kelas_id': kelasId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['success'] == true) {
        return GuruPickupResult(
          success: true,
          message: responseData['message'] ?? 'Siswa berhasil ditambahkan!',
        );
      } else {
        return GuruPickupResult(
          success: false,
          message: responseData['message'] ?? 'Gagal menambahkan siswa.',
        );
      }
    } catch (e) {
      debugPrint('Error adding student: $e');
      return GuruPickupResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Ambil riwayat panggilan yang sudah dilakukan
  Future<PickupHistoryResult> getPickupHistory({DateTime? tanggal}) async {
    try {
      final queryParams = <String, String>{};
      if (tanggal != null) {
        queryParams['tanggal'] =
            '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
      }

      // Use the correct endpoint from web_server/service/riwayat/
      final uri = Uri.parse(
        'https://soulhbc.com/penjemputan/service/riwayat/get_all_history.php',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = (data['data'] as List)
              .map((json) => PickupHistoryItemData.fromJson(json))
              .toList();
          return PickupHistoryResult(success: true, data: items, message: '');
        }
      }
      return PickupHistoryResult(
        success: false,
        data: [],
        message: 'Gagal memuat riwayat',
      );
    } catch (e) {
      debugPrint('Error fetching pickup history: $e');
      return PickupHistoryResult(
        success: false,
        data: [],
        message: 'Tidak dapat terhubung ke server',
      );
    }
  }

  /// Ambil antrean penjemputan saat ini
  Future<PickupQueueResult> getPickupQueue() async {
    try {
      // Use the correct endpoint from web_server/service/pickup/
      final response = await http.get(
        Uri.parse(
          'https://soulhbc.com/penjemputan/service/pickup/get_pickup_queue.php',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response has 'queue' array, not 'data'
        if (data['success'] == true && data['queue'] != null) {
          final items = (data['queue'] as List)
              .map((json) => QueueItemData.fromJson(json))
              .toList();
          return PickupQueueResult(success: true, data: items, message: '');
        }
      }
      return PickupQueueResult(
        success: false,
        data: [],
        message: 'Gagal memuat antrean',
      );
    } catch (e) {
      debugPrint('Error fetching pickup queue: $e');
      return PickupQueueResult(
        success: false,
        data: [],
        message: 'Tidak dapat terhubung ke server',
      );
    }
  }

  /// Tandai siswa sudah dijemput
  Future<GuruPickupResult> markAsPickedUp({required int siswaId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mark_picked_up.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'siswa_id': siswaId}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return GuruPickupResult(
          success: true,
          message:
              responseData['message'] ??
              'Siswa berhasil ditandai sudah dijemput!',
        );
      } else {
        return GuruPickupResult(
          success: false,
          message: responseData['message'] ?? 'Gagal menandai siswa.',
        );
      }
    } catch (e) {
      return GuruPickupResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }
}

/// Model untuk item riwayat pickup
class PickupHistoryItemData {
  final int id;
  final String namaSiswa;
  final String namaKelas;
  final String waktu;
  final String penjemput;
  final String status;
  final String? fotoUrl;
  final DateTime tanggal;

  PickupHistoryItemData({
    required this.id,
    required this.namaSiswa,
    required this.namaKelas,
    required this.waktu,
    required this.penjemput,
    required this.status,
    this.fotoUrl,
    required this.tanggal,
  });

  factory PickupHistoryItemData.fromJson(Map<String, dynamic> json) {
    return PickupHistoryItemData(
      id: json['id'] ?? 0,
      namaSiswa: json['nama_siswa'] ?? '',
      namaKelas: json['nama_kelas'] ?? '',
      waktu: json['waktu'] ?? '', // API returns 'waktu' as HH:mm
      penjemput: json['penjemput'] ?? '',
      status: json['status'] ?? '',
      fotoUrl: json['foto_url'],
      tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Result wrapper untuk riwayat pickup
class PickupHistoryResult {
  final bool success;
  final List<PickupHistoryItemData> data;
  final String message;

  PickupHistoryResult({
    required this.success,
    required this.data,
    required this.message,
  });
}

/// Model untuk item antrean
class QueueItemData {
  final int id;
  final int siswaId;
  final String namaSiswa;
  final String namaKelas;
  final String penjemput;
  final String status;
  final String? fotoUrl;
  final int nomorAntrian;
  final DateTime timestamp;

  QueueItemData({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.namaKelas,
    required this.penjemput,
    required this.status,
    this.fotoUrl,
    required this.nomorAntrian,
    required this.timestamp,
  });

  factory QueueItemData.fromJson(Map<String, dynamic> json) {
    return QueueItemData(
      id: json['id'] ?? 0,
      siswaId:
          json['siswa_id'] ??
          json['id'] ??
          0, // fallback to id if siswa_id not present
      namaSiswa: json['nama_siswa'] ?? '',
      namaKelas: json['nama_kelas'] ?? '',
      penjemput: json['penjemput'] ?? '',
      status: json['status'] ?? '',
      fotoUrl: json['foto_url'],
      nomorAntrian: json['nomor_antrian'] ?? 0,
      timestamp:
          DateTime.tryParse(json['waktu_request'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Result wrapper untuk antrean pickup
class PickupQueueResult {
  final bool success;
  final List<QueueItemData> data;
  final String message;

  PickupQueueResult({
    required this.success,
    required this.data,
    required this.message,
  });
}
