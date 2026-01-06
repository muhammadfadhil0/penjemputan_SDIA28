/// Model untuk data user yang login (siswa atau guru)
class SiswaUser {
  final int id;
  final String username;
  final String nama;
  final String? namaPanggilan;
  final String role; // 'siswa', 'guru', 'class_viewer'
  final int? kelasId; // Nullable untuk guru
  final String? namaKelas; // Nullable untuk guru
  final int? tingkat; // Nullable untuk guru
  final String? fotoUrl;
  final String? noTeleponOrtu;
  final String? noTelepon; // Untuk guru

  SiswaUser({
    required this.id,
    required this.username,
    required this.nama,
    this.namaPanggilan,
    required this.role,
    this.kelasId,
    this.namaKelas,
    this.tingkat,
    this.fotoUrl,
    this.noTeleponOrtu,
    this.noTelepon,
  });

  /// Membuat SiswaUser dari JSON response API (siswa)
  factory SiswaUser.fromJson(Map<String, dynamic> json) {
    return SiswaUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nama: json['nama'] as String,
      namaPanggilan: json['nama_panggilan'] as String?,
      role: json['role'] as String? ?? 'siswa',
      kelasId: json['kelas_id'] as int?,
      namaKelas: json['nama_kelas'] as String?,
      tingkat: json['tingkat'] as int?,
      fotoUrl: json['foto_url'] as String? ?? json['foto'] as String?,
      noTeleponOrtu: json['no_telepon_ortu'] as String?,
      noTelepon: json['no_telepon'] as String?,
    );
  }

  /// Konversi SiswaUser ke JSON untuk penyimpanan lokal
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama': nama,
      'nama_panggilan': namaPanggilan,
      'role': role,
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
      'tingkat': tingkat,
      'foto_url': fotoUrl,
      'no_telepon_ortu': noTeleponOrtu,
      'no_telepon': noTelepon,
    };
  }

  /// Cek apakah user adalah guru
  bool get isGuru => role == 'guru';

  /// Cek apakah user adalah siswa
  bool get isSiswa => role == 'siswa';

  /// Mendapatkan nama tampilan (nama panggilan atau nama lengkap)
  String get displayName => namaPanggilan ?? nama.split(' ').first;

  /// Copy with method
  SiswaUser copyWith({
    int? id,
    String? username,
    String? nama,
    String? namaPanggilan,
    String? role,
    int? kelasId,
    String? namaKelas,
    int? tingkat,
    String? fotoUrl,
    String? noTeleponOrtu,
    String? noTelepon,
  }) {
    return SiswaUser(
      id: id ?? this.id,
      username: username ?? this.username,
      nama: nama ?? this.nama,
      namaPanggilan: namaPanggilan ?? this.namaPanggilan,
      role: role ?? this.role,
      kelasId: kelasId ?? this.kelasId,
      namaKelas: namaKelas ?? this.namaKelas,
      tingkat: tingkat ?? this.tingkat,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      noTeleponOrtu: noTeleponOrtu ?? this.noTeleponOrtu,
      noTelepon: noTelepon ?? this.noTelepon,
    );
  }
}
