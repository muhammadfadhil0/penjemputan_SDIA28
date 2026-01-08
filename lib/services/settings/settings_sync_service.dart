import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'siswa_settings_model.dart';

/// Service untuk sinkronisasi settings antar device
/// Mengimplementasikan hybrid approach: local cache + server sync
class SettingsSyncService extends ChangeNotifier {
  // Base URL API
  static const String _baseUrl =
      'https://soulhbc.com/penjemputan/service/settings';

  // Key prefix untuk SharedPreferences
  static const String _settingsPrefix = 'siswa_settings_';
  static const String _pendingSyncKey = 'pending_settings_sync';

  // Singleton instance
  static final SettingsSyncService _instance = SettingsSyncService._internal();
  factory SettingsSyncService() => _instance;
  SettingsSyncService._internal();

  // Cache settings di memory
  final Map<int, SiswaSettings> _settingsCache = {};

  // Flag untuk tracking sync status
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ==========================================
  // LOAD SETTINGS (Cache First, then Server)
  // ==========================================

  /// Load settings untuk siswa tertentu
  /// Flow: Load cache → return → fetch server → update if different
  Future<SiswaSettings> loadSettings(int siswaId) async {
    // 1. Load dari local cache dulu (instant)
    final cachedSettings = await _loadFromCache(siswaId);
    _settingsCache[siswaId] = cachedSettings;

    // 2. Fetch dari server di background
    _fetchFromServerAndSync(siswaId);

    return cachedSettings;
  }

  /// Load settings dari local cache (SharedPreferences)
  Future<SiswaSettings> _loadFromCache(int siswaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$siswaId';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return SiswaSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('SettingsSyncService: Error loading from cache: $e');
    }

    return SiswaSettings.defaults();
  }

  /// Simpan settings ke local cache
  Future<void> _saveToCache(int siswaId, SiswaSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$siswaId';
      await prefs.setString(key, jsonEncode(settings.toJson()));
      debugPrint('SettingsSyncService: Saved to cache for siswa $siswaId');
    } catch (e) {
      debugPrint('SettingsSyncService: Error saving to cache: $e');
    }
  }

  // ==========================================
  // SERVER SYNC
  // ==========================================

  /// Fetch settings dari server dan sync dengan cache
  Future<void> _fetchFromServerAndSync(int siswaId) async {
    try {
      final serverSettings = await _fetchFromServer(siswaId);
      if (serverSettings == null) return;

      final cachedSettings =
          _settingsCache[siswaId] ?? SiswaSettings.defaults();

      // Jika server data berbeda, update cache dan notify
      if (!cachedSettings.isEqualTo(serverSettings)) {
        debugPrint('SettingsSyncService: Server data differs, updating cache');
        _settingsCache[siswaId] = serverSettings;
        await _saveToCache(siswaId, serverSettings);
        notifyListeners(); // Trigger UI refresh
      }
    } catch (e) {
      debugPrint('SettingsSyncService: Error syncing from server: $e');
    }
  }

  /// Fetch settings dari server API
  Future<SiswaSettings?> _fetchFromServer(int siswaId) async {
    try {
      final url = '$_baseUrl/get_siswa_settings.php?siswa_id=$siswaId';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return SiswaSettings.fromJson(json['data']);
        }
      }
    } catch (e) {
      debugPrint('SettingsSyncService: Error fetching from server: $e');
    }
    return null;
  }

  // ==========================================
  // SAVE SETTINGS (Cache + Server)
  // ==========================================

  /// Simpan settings - update cache dulu, lalu kirim ke server
  Future<bool> saveSettings(int siswaId, SiswaSettings settings) async {
    // 1. Update local cache dulu (instant feedback)
    final settingsWithTimestamp = settings.copyWith(updatedAt: DateTime.now());
    _settingsCache[siswaId] = settingsWithTimestamp;
    await _saveToCache(siswaId, settingsWithTimestamp);
    notifyListeners();

    // 2. Kirim ke server
    final success = await _sendToServer(siswaId, settingsWithTimestamp);

    if (!success) {
      // 3. Jika gagal (offline), tambahkan ke pending sync
      await _addToPendingSync(siswaId);
      debugPrint('SettingsSyncService: Added to pending sync queue');
    }

    return success;
  }

  /// Kirim settings ke server API
  Future<bool> _sendToServer(int siswaId, SiswaSettings settings) async {
    try {
      final url = '$_baseUrl/update_siswa_settings.php';
      final body = {'siswa_id': siswaId, ...settings.toJson()};

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          debugPrint(
            'SettingsSyncService: Settings sent to server successfully',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('SettingsSyncService: Error sending to server: $e');
    }
    return false;
  }

  // ==========================================
  // PENDING SYNC (Offline Mode)
  // ==========================================

  /// Tambahkan siswa ID ke queue pending sync
  Future<void> _addToPendingSync(int siswaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingSyncKey) ?? [];

      final siswaIdStr = siswaId.toString();
      if (!pendingList.contains(siswaIdStr)) {
        pendingList.add(siswaIdStr);
        await prefs.setStringList(_pendingSyncKey, pendingList);
      }
    } catch (e) {
      debugPrint('SettingsSyncService: Error adding to pending sync: $e');
    }
  }

  /// Hapus siswa ID dari queue pending sync
  Future<void> _removeFromPendingSync(int siswaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingSyncKey) ?? [];

      pendingList.remove(siswaId.toString());
      await prefs.setStringList(_pendingSyncKey, pendingList);
    } catch (e) {
      debugPrint('SettingsSyncService: Error removing from pending sync: $e');
    }
  }

  /// Sync semua pending changes saat online
  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Cek koneksi internet
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint('SettingsSyncService: No internet, skipping pending sync');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingSyncKey) ?? [];

      if (pendingList.isEmpty) {
        debugPrint('SettingsSyncService: No pending sync');
        return;
      }

      debugPrint(
        'SettingsSyncService: Syncing ${pendingList.length} pending changes',
      );

      for (final siswaIdStr in List.from(pendingList)) {
        final siswaId = int.tryParse(siswaIdStr);
        if (siswaId == null) continue;

        // Load settings dari cache
        final settings = await _loadFromCache(siswaId);

        // Kirim ke server
        final success = await _sendToServer(siswaId, settings);

        if (success) {
          await _removeFromPendingSync(siswaId);
          debugPrint('SettingsSyncService: Synced pending for siswa $siswaId');
        }
      }
    } catch (e) {
      debugPrint('SettingsSyncService: Error syncing pending: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Get cached settings untuk siswa (tanpa reload)
  SiswaSettings? getCachedSettings(int siswaId) {
    return _settingsCache[siswaId];
  }

  /// Force refresh settings dari server
  Future<SiswaSettings?> forceRefresh(int siswaId) async {
    final serverSettings = await _fetchFromServer(siswaId);
    if (serverSettings != null) {
      _settingsCache[siswaId] = serverSettings;
      await _saveToCache(siswaId, serverSettings);
      notifyListeners();
    }
    return serverSettings;
  }

  /// Clear cache untuk siswa tertentu (saat logout)
  Future<void> clearCache(int siswaId) async {
    _settingsCache.remove(siswaId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_settingsPrefix$siswaId');
    } catch (e) {
      debugPrint('SettingsSyncService: Error clearing cache: $e');
    }
  }

  /// Clear semua cache (saat logout all accounts)
  Future<void> clearAllCache() async {
    _settingsCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_settingsPrefix)) {
          await prefs.remove(key);
        }
      }
      await prefs.remove(_pendingSyncKey);
    } catch (e) {
      debugPrint('SettingsSyncService: Error clearing all cache: $e');
    }
  }
}
