/// Model untuk data kelas
class KelasInfo {
  final int id;
  final String namaKelas;
  final int tingkat;
  final String? tahunAjaran;

  KelasInfo({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    this.tahunAjaran,
  });

  factory KelasInfo.fromJson(Map<String, dynamic> json) {
    return KelasInfo(
      id: json['id'] as int,
      namaKelas: json['nama_kelas'] as String,
      tingkat: json['tingkat'] as int,
      tahunAjaran: json['tahun_ajaran'] as String?,
    );
  }
}

/// Model untuk statistik penjemputan kelas
class KelasStatistik {
  final int total;
  final int sudahDijemput;
  final int belumDijemput;

  KelasStatistik({
    required this.total,
    required this.sudahDijemput,
    required this.belumDijemput,
  });

  factory KelasStatistik.fromJson(Map<String, dynamic> json) {
    return KelasStatistik(
      total: json['total'] as int,
      sudahDijemput: json['sudah_dijemput'] as int,
      belumDijemput: json['belum_dijemput'] as int,
    );
  }

  double get persentaseDijemput =>
      total == 0 ? 0 : (sudahDijemput / total * 100);
}

/// Model untuk data siswa dalam kelas
class KelasStudent {
  final int id;
  final String nama;
  final String namaPanggilan;
  final String? fotoUrl;
  final bool sudahDijemput;
  final String? waktuDijemput;
  final String? penjemput;

  KelasStudent({
    required this.id,
    required this.nama,
    required this.namaPanggilan,
    this.fotoUrl,
    required this.sudahDijemput,
    this.waktuDijemput,
    this.penjemput,
  });

  factory KelasStudent.fromJson(Map<String, dynamic> json) {
    return KelasStudent(
      id: json['id'] as int,
      nama: json['nama'] as String,
      namaPanggilan:
          json['nama_panggilan'] as String? ?? json['nama'] as String,
      fotoUrl: json['foto_url'] as String?,
      sudahDijemput: json['sudah_dijemput'] as bool? ?? false,
      waktuDijemput: json['waktu_dijemput'] as String?,
      penjemput: json['penjemput'] as String?,
    );
  }

  /// Mendapatkan inisial dari nama panggilan
  String get inisial {
    final parts = namaPanggilan.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return namaPanggilan
        .substring(0, namaPanggilan.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}

/// Response untuk endpoint get_students
class KelasStudentsResponse {
  final bool success;
  final String message;
  final KelasInfo? kelas;
  final KelasStatistik? statistik;
  final List<KelasStudent> students;

  KelasStudentsResponse({
    required this.success,
    required this.message,
    this.kelas,
    this.statistik,
    required this.students,
  });

  factory KelasStudentsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return KelasStudentsResponse(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      kelas: data != null && data['kelas'] != null
          ? KelasInfo.fromJson(data['kelas'] as Map<String, dynamic>)
          : null,
      statistik: data != null && data['statistik'] != null
          ? KelasStatistik.fromJson(data['statistik'] as Map<String, dynamic>)
          : null,
      students: data != null && data['students'] != null
          ? (data['students'] as List)
                .map((e) => KelasStudent.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}

/// Model untuk item riwayat penjemputan
class KelasHistoryItem {
  final int id;
  final int siswaId;
  final String namaSiswa;
  final String namaAsli;
  final String? namaLengkap;
  final String penjemput;
  final String? penjemputRaw;
  final String status;
  final int panggilanKe;
  final String waktu;
  final String? waktuFull;

  KelasHistoryItem({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.namaAsli,
    this.namaLengkap,
    required this.penjemput,
    this.penjemputRaw,
    required this.status,
    required this.panggilanKe,
    required this.waktu,
    this.waktuFull,
  });

  factory KelasHistoryItem.fromJson(Map<String, dynamic> json) {
    return KelasHistoryItem(
      id: json['id'] as int,
      siswaId: json['siswa_id'] as int,
      namaSiswa: json['nama_siswa'] as String,
      namaAsli: json['nama_asli'] as String? ?? json['nama_siswa'] as String,
      namaLengkap: json['nama_lengkap'] as String?,
      penjemput: json['penjemput'] as String,
      penjemputRaw: json['penjemput_raw'] as String?,
      status: json['status'] as String,
      panggilanKe: json['panggilan_ke'] as int? ?? 1,
      waktu: json['waktu'] as String,
      waktuFull: json['waktu_full'] as String?,
    );
  }

  /// Cek apakah ini panggilan kedua atau lebih
  bool get isMultipleCall => panggilanKe > 1;
}

/// Response untuk endpoint get_class_history
class KelasHistoryResponse {
  final bool success;
  final String message;
  final String? tanggal;
  final int count;
  final List<KelasHistoryItem> data;

  KelasHistoryResponse({
    required this.success,
    required this.message,
    this.tanggal,
    required this.count,
    required this.data,
  });

  factory KelasHistoryResponse.fromJson(Map<String, dynamic> json) {
    return KelasHistoryResponse(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      tanggal: json['tanggal'] as String?,
      count: json['count'] as int? ?? 0,
      data: json['data'] != null
          ? (json['data'] as List)
                .map(
                  (e) => KelasHistoryItem.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}
