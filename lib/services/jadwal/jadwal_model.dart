/// Model untuk data jadwal harian
class JadwalItem {
  final int? id;
  final String hari;
  final String jamMasuk;
  final String jamPulang;
  final bool isHoliday;
  final bool isToday;

  const JadwalItem({
    this.id,
    required this.hari,
    required this.jamMasuk,
    required this.jamPulang,
    this.isHoliday = false,
    this.isToday = false,
  });

  /// Membuat JadwalItem dari JSON response API
  factory JadwalItem.fromJson(
    Map<String, dynamic> json, {
    bool isToday = false,
  }) {
    return JadwalItem(
      id: json['id'] as int?,
      hari: _capitalizeFirst(json['hari'] as String),
      jamMasuk: json['jam_masuk'] as String? ?? '07:00',
      jamPulang: json['jam_pulang'] as String? ?? '14:00',
      isHoliday: json['is_holiday'] == true || json['is_holiday'] == 1,
      isToday: isToday,
    );
  }

  /// Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hari': hari.toLowerCase(),
      'jam_masuk': jamMasuk,
      'jam_pulang': jamPulang,
      'is_holiday': isHoliday,
    };
  }

  /// Mendapatkan singkatan hari (2 huruf pertama)
  String get dayShort => hari.substring(0, 2);

  /// Getter alternatif untuk jam pulang (untuk konsistensi dengan UI)
  String get jamKeluar => jamPulang;

  /// Helper untuk capitalize huruf pertama
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Copy with untuk membuat salinan dengan modifikasi
  JadwalItem copyWith({
    int? id,
    String? hari,
    String? jamMasuk,
    String? jamPulang,
    bool? isHoliday,
    bool? isToday,
  }) {
    return JadwalItem(
      id: id ?? this.id,
      hari: hari ?? this.hari,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamPulang: jamPulang ?? this.jamPulang,
      isHoliday: isHoliday ?? this.isHoliday,
      isToday: isToday ?? this.isToday,
    );
  }
}

/// Model untuk jadwal lengkap satu kelas
class JadwalKelas {
  final int kelasId;
  final String namaKelas;
  final int tingkat;
  final List<JadwalItem> jadwalList;

  const JadwalKelas({
    required this.kelasId,
    required this.namaKelas,
    required this.tingkat,
    required this.jadwalList,
  });

  /// Membuat JadwalKelas dari JSON response API
  factory JadwalKelas.fromJson(Map<String, dynamic> json) {
    // Urutan hari dalam seminggu
    const dayOrder = ['senin', 'selasa', 'rabu', 'kamis', 'jumat'];

    // Tentukan hari ini
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0 = Senin, 4 = Jumat
    final todayName = todayIndex >= 0 && todayIndex < dayOrder.length
        ? dayOrder[todayIndex]
        : '';

    // Parse jadwal dari response
    final jadwalMap = json['jadwal'] as Map<String, dynamic>? ?? {};
    final List<JadwalItem> jadwalList = [];

    // Urutkan berdasarkan hari
    for (final hari in dayOrder) {
      if (jadwalMap.containsKey(hari)) {
        final jadwalData = jadwalMap[hari] as Map<String, dynamic>;
        jadwalList.add(
          JadwalItem.fromJson({
            ...jadwalData,
            'hari': hari,
          }, isToday: hari == todayName),
        );
      } else {
        // Default jika tidak ada data
        jadwalList.add(
          JadwalItem(
            hari: JadwalItem._capitalizeFirst(hari),
            jamMasuk: '07:00',
            jamPulang: '14:00',
            isToday: hari == todayName,
          ),
        );
      }
    }

    return JadwalKelas(
      kelasId: json['kelas_id'] as int? ?? 0,
      namaKelas: json['nama_kelas'] as String? ?? '',
      tingkat: json['tingkat'] as int? ?? 0,
      jadwalList: jadwalList,
    );
  }

  /// Mendapatkan jadwal hari ini
  JadwalItem? get todaySchedule {
    try {
      return jadwalList.firstWhere((item) => item.isToday);
    } catch (_) {
      return null;
    }
  }
}
