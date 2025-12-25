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

  /// Getter untuk user saat ini
  SiswaUser? get currentUser => _currentUser;

  /// Cek apakah user sudah login
  bool get isLoggedIn => _currentUser != null;

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
  }

  /// Cek apakah ada session tersimpan
  Future<bool> hasStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
