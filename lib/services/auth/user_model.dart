/// Model untuk data siswa yang login
class SiswaUser {
  final int id;
  final String username;
  final String nama;
  final String? namaPanggilan;
  final String role;
  final int kelasId;
  final String namaKelas;
  final int tingkat;
  final String? fotoUrl;
  final String? noTeleponOrtu;

  SiswaUser({
    required this.id,
    required this.username,
    required this.nama,
    this.namaPanggilan,
    required this.role,
    required this.kelasId,
    required this.namaKelas,
    required this.tingkat,
    this.fotoUrl,
    this.noTeleponOrtu,
  });

  /// Membuat SiswaUser dari JSON response API
  factory SiswaUser.fromJson(Map<String, dynamic> json) {
    return SiswaUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nama: json['nama'] as String,
      namaPanggilan: json['nama_panggilan'] as String?,
      role: json['role'] as String,
      kelasId: json['kelas_id'] as int,
      namaKelas: json['nama_kelas'] as String,
      tingkat: json['tingkat'] as int,
      fotoUrl: json['foto_url'] as String?,
      noTeleponOrtu: json['no_telepon_ortu'] as String?,
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
    };
  }

  /// Mendapatkan nama tampilan (nama panggilan atau nama lengkap)
  String get displayName => namaPanggilan ?? nama.split(' ').first;
}
