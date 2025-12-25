/// Model untuk Riwayat Penjemputan
class RiwayatPenjemputan {
  final int id;
  final int siswaId;
  final DateTime tanggal;
  final String tanggalText;
  final String waktu;
  final String penjemput;
  final String? penjemputRaw;
  final String? penjemputDetail;
  final String status;
  final String catatan;
  final int nomorAntrian;
  final DateTime waktuRequest;
  final DateTime? waktuDipanggil;
  final DateTime? waktuDijemput;
  final String namaSiswa;
  final String namaKelas;

  RiwayatPenjemputan({
    required this.id,
    required this.siswaId,
    required this.tanggal,
    required this.tanggalText,
    required this.waktu,
    required this.penjemput,
    this.penjemputRaw,
    this.penjemputDetail,
    required this.status,
    required this.catatan,
    required this.nomorAntrian,
    required this.waktuRequest,
    this.waktuDipanggil,
    this.waktuDijemput,
    required this.namaSiswa,
    required this.namaKelas,
  });

  /// Factory constructor untuk parsing dari JSON
  factory RiwayatPenjemputan.fromJson(Map<String, dynamic> json) {
    return RiwayatPenjemputan(
      id: json['id'] ?? 0,
      siswaId: json['siswa_id'] ?? 0,
      tanggal: DateTime.parse(json['tanggal']),
      tanggalText: json['tanggalText'] ?? '',
      waktu: json['waktu'] ?? '',
      penjemput: json['penjemput'] ?? '',
      penjemputRaw: json['penjemput_raw'],
      penjemputDetail: json['penjemput_detail'],
      status: json['status'] ?? 'menunggu',
      catatan: json['catatan'] ?? '',
      nomorAntrian: json['nomor_antrian'] ?? 0,
      waktuRequest: DateTime.parse(json['waktu_request']),
      waktuDipanggil: json['waktu_dipanggil'] != null
          ? DateTime.parse(json['waktu_dipanggil'])
          : null,
      waktuDijemput: json['waktu_dijemput'] != null
          ? DateTime.parse(json['waktu_dijemput'])
          : null,
      namaSiswa: json['nama_siswa'] ?? '',
      namaKelas: json['nama_kelas'] ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siswa_id': siswaId,
      'tanggal': tanggal.toIso8601String().split('T').first,
      'tanggalText': tanggalText,
      'waktu': waktu,
      'penjemput': penjemput,
      'penjemput_raw': penjemputRaw,
      'penjemput_detail': penjemputDetail,
      'status': status,
      'catatan': catatan,
      'nomor_antrian': nomorAntrian,
      'waktu_request': waktuRequest.toIso8601String(),
      'waktu_dipanggil': waktuDipanggil?.toIso8601String(),
      'waktu_dijemput': waktuDijemput?.toIso8601String(),
      'nama_siswa': namaSiswa,
      'nama_kelas': namaKelas,
    };
  }

  /// Cek apakah status selesai (dijemput)
  bool get isSelesai => status == 'dijemput';

  /// Cek apakah status sedang dipanggil
  bool get isDipanggil => status == 'dipanggil';

  /// Cek apakah status dibatalkan
  bool get isDibatalkan => status == 'dibatalkan';

  /// Cek apakah status menunggu
  bool get isMenunggu => status == 'menunggu';

  /// Cek apakah tepat waktu (untuk catatan)
  bool get isTepatWaktu => catatan == 'Tepat waktu';
}

/// Response wrapper untuk hasil fetch riwayat
class RiwayatResult {
  final bool success;
  final String message;
  final List<RiwayatPenjemputan> data;
  final int count;

  RiwayatResult({
    required this.success,
    required this.message,
    this.data = const [],
    this.count = 0,
  });

  factory RiwayatResult.fromJson(Map<String, dynamic> json) {
    List<RiwayatPenjemputan> riwayatList = [];

    if (json['data'] != null) {
      riwayatList = (json['data'] as List)
          .map((item) => RiwayatPenjemputan.fromJson(item))
          .toList();
    }

    return RiwayatResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: riwayatList,
      count: json['count'] ?? riwayatList.length,
    );
  }
}
