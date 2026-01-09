import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';
import 'auth_service.dart';

/// Service untuk mengelola multiple akun guru dan kelas
/// Memungkinkan guru menambah, menghapus, dan beralih antar akun guru/kelas
class GuruMultiAccountService extends ChangeNotifier {
  // Key untuk menyimpan list akun di SharedPreferences
  static const String _accountsKey = 'guru_multi_accounts_list';
  static const String _activeAccountIdKey = 'guru_active_account_id';

  /// Singleton instance
  static final GuruMultiAccountService _instance =
      GuruMultiAccountService._internal();
  factory GuruMultiAccountService() => _instance;
  GuruMultiAccountService._internal();

  /// List semua akun yang terdaftar (guru dan kelas)
  List<SiswaUser> _accounts = [];
  List<SiswaUser> get accounts => List.unmodifiable(_accounts);

  /// ID akun yang sedang aktif
  int? _activeAccountId;
  int? get activeAccountId => _activeAccountId;

  /// Apakah ada multiple akun
  bool get hasMultipleAccounts => _accounts.length > 1;

  /// Jumlah akun
  int get accountCount => _accounts.length;

  /// Akun yang sedang aktif
  SiswaUser? get activeAccount {
    if (_activeAccountId == null) return null;
    try {
      return _accounts.firstWhere((acc) => acc.id == _activeAccountId);
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }

  /// Get akun guru (role = 'guru')
  SiswaUser? get guruAccount {
    try {
      return _accounts.firstWhere((acc) => acc.isGuru);
    } catch (e) {
      return null;
    }
  }

  /// Get list akun kelas (role = 'kelas' atau 'class_viewer')
  List<SiswaUser> get kelasAccounts {
    return _accounts.where((acc) => acc.isKelas).toList();
  }

  /// Inisialisasi service - load data dari storage
  Future<void> init() async {
    await _loadAccountsFromStorage();
  }

  /// Load semua akun dari SharedPreferences
  Future<void> _loadAccountsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load list akun
      final accountsJson = prefs.getString(_accountsKey);
      if (accountsJson != null) {
        final List<dynamic> accountsList = jsonDecode(accountsJson);
        _accounts = accountsList
            .map((json) => SiswaUser.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load active account ID
      _activeAccountId = prefs.getInt(_activeAccountIdKey);

      // Jika tidak ada active account tapi ada akun, set yang pertama
      if (_activeAccountId == null && _accounts.isNotEmpty) {
        _activeAccountId = _accounts.first.id;
        await prefs.setInt(_activeAccountIdKey, _activeAccountId!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading guru accounts: $e');
    }
  }

  /// Simpan list akun ke SharedPreferences
  Future<void> _saveAccountsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = jsonEncode(
        _accounts.map((acc) => acc.toJson()).toList(),
      );
      await prefs.setString(_accountsKey, accountsJson);

      if (_activeAccountId != null) {
        await prefs.setInt(_activeAccountIdKey, _activeAccountId!);
      }
    } catch (e) {
      debugPrint('Error saving guru accounts: $e');
    }
  }

  /// Tambahkan akun baru
  /// Return true jika berhasil, false jika akun sudah ada
  Future<bool> addAccount(SiswaUser user) async {
    // Cek apakah akun sudah ada
    final exists = _accounts.any((acc) => acc.id == user.id);
    if (exists) {
      return false;
    }

    _accounts.add(user);

    // Jika ini akun pertama, jadikan aktif
    if (_accounts.length == 1) {
      _activeAccountId = user.id;
    }

    await _saveAccountsToStorage();
    notifyListeners();
    return true;
  }

  /// Update data akun yang sudah ada
  Future<void> updateAccount(SiswaUser user) async {
    final index = _accounts.indexWhere((acc) => acc.id == user.id);
    if (index != -1) {
      _accounts[index] = user;
      await _saveAccountsToStorage();
      notifyListeners();
    }
  }

  /// Hapus akun dari list
  Future<void> removeAccount(int userId) async {
    _accounts.removeWhere((acc) => acc.id == userId);

    // Jika akun yang dihapus adalah akun aktif, switch ke akun lain
    if (_activeAccountId == userId) {
      _activeAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;

      // Update AuthService dengan akun baru
      if (_activeAccountId != null) {
        final newActiveAccount = activeAccount;
        if (newActiveAccount != null) {
          await AuthService().switchToAccount(newActiveAccount);
        }
      }
    }

    await _saveAccountsToStorage();
    notifyListeners();
  }

  /// Switch ke akun lain
  Future<bool> switchAccount(int userId) async {
    final account = _accounts.firstWhere(
      (acc) => acc.id == userId,
      orElse: () => throw Exception('Account not found'),
    );

    _activeAccountId = userId;
    await _saveAccountsToStorage();

    // Update AuthService dengan akun baru
    await AuthService().switchToAccount(account);

    notifyListeners();
    return true;
  }

  /// Cek apakah akun sudah terdaftar
  bool isAccountRegistered(int userId) {
    return _accounts.any((acc) => acc.id == userId);
  }

  /// Hapus semua akun (untuk logout semua)
  Future<void> clearAllAccounts() async {
    _accounts.clear();
    _activeAccountId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountsKey);
    await prefs.remove(_activeAccountIdKey);

    notifyListeners();
  }

  /// Dapatkan akun lain (selain yang aktif)
  List<SiswaUser> get otherAccounts {
    return _accounts.where((acc) => acc.id != _activeAccountId).toList();
  }
}
