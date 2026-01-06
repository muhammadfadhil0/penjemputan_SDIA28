import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';

/// Response wrapper untuk hasil autentikasi
class AuthResult {
  final bool success;
  final String message;
  final SiswaUser? user;

  AuthResult({required this.success, required this.message, this.user});
}

/// Callback untuk notifikasi perubahan akun
typedef OnAccountChangedCallback = void Function(SiswaUser? user);

/// Service untuk menangani autentikasi siswa
class AuthService {
  // Base URL untuk API backend
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/auth_login';

  // Key untuk menyimpan data user di SharedPreferences
  static const String _userKey = 'logged_in_user';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// User yang sedang login (cached dalam memory)
  SiswaUser? _currentUser;

  /// List of listeners for account changes
  final List<OnAccountChangedCallback> _accountChangedListeners = [];

  /// Getter untuk user saat ini
  SiswaUser? get currentUser => _currentUser;

  /// Cek apakah user sudah login
  bool get isLoggedIn => _currentUser != null;

  /// Tambah listener untuk perubahan akun
  void addAccountChangedListener(OnAccountChangedCallback callback) {
    _accountChangedListeners.add(callback);
  }

  /// Hapus listener
  void removeAccountChangedListener(OnAccountChangedCallback callback) {
    _accountChangedListeners.remove(callback);
  }

  /// Notify semua listeners tentang perubahan akun
  void _notifyAccountChanged() {
    for (final listener in _accountChangedListeners) {
      listener(_currentUser);
    }
  }

  /// Switch ke akun lain (digunakan oleh MultiAccountService)
  Future<void> switchToAccount(SiswaUser user) async {
    _currentUser = user;
    await _saveUserToStorage(user);
    _notifyAccountChanged();
  }

  /// Login dengan username dan password siswa
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Parse user data
        final user = SiswaUser.fromJson(responseData['data']);

        // Simpan ke memory dan local storage
        _currentUser = user;
        await _saveUserToStorage(user);

        // Notify listeners about the account change
        _notifyAccountChanged();

        return AuthResult(
          success: true,
          message: responseData['message'] ?? 'Login berhasil!',
          user: user,
        );
      } else {
        return AuthResult(
          success: false,
          message: responseData['message'] ?? 'Login gagal.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Menyimpan user data ke SharedPreferences
  Future<void> _saveUserToStorage(SiswaUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Memuat user data dari SharedPreferences saat app startup
  Future<bool> loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn) return false;

      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = SiswaUser.fromJson(userData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout dan hapus data user dari storage
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    // Reset onboarding flag so it shows again on next login
    await prefs.remove('has_seen_jemput_onboarding');
  }

  /// Cek apakah ada session tersimpan
  Future<bool> hasStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Update foto profil user di memory dan storage
  Future<void> updateUserFoto(String? fotoUrl) async {
    if (_currentUser != null) {
      // Buat user baru dengan foto yang diupdate
      _currentUser = SiswaUser(
        id: _currentUser!.id,
        username: _currentUser!.username,
        nama: _currentUser!.nama,
        namaPanggilan: _currentUser!.namaPanggilan,
        role: _currentUser!.role,
        kelasId: _currentUser!.kelasId,
        namaKelas: _currentUser!.namaKelas,
        tingkat: _currentUser!.tingkat,
        fotoUrl: fotoUrl,
        noTeleponOrtu: _currentUser!.noTeleponOrtu,
      );

      // Simpan ke storage
      await _saveUserToStorage(_currentUser!);
    }
  }

  /// Update profile user (nama dan nama panggilan) di memory dan storage
  Future<void> updateUserProfile({
    required String nama,
    String? namaPanggilan,
  }) async {
    if (_currentUser != null) {
      // Buat user baru dengan data yang diupdate
      _currentUser = SiswaUser(
        id: _currentUser!.id,
        username: _currentUser!.username,
        nama: nama,
        namaPanggilan: namaPanggilan,
        role: _currentUser!.role,
        kelasId: _currentUser!.kelasId,
        namaKelas: _currentUser!.namaKelas,
        tingkat: _currentUser!.tingkat,
        fotoUrl: _currentUser!.fotoUrl,
        noTeleponOrtu: _currentUser!.noTeleponOrtu,
      );

      // Simpan ke storage
      await _saveUserToStorage(_currentUser!);
    }
  }
}
