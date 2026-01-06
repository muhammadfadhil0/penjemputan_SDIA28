import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk mengambil pengaturan aplikasi dari server
class ConfigService {
  // Singleton pattern
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // Base URL for API (same base as auth service)
  static const String _baseUrl = 'https://soulhbc.com/penjemputan';

  // Cache untuk menyimpan pengaturan
  Map<String, dynamic> _settingsCache = {};
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Cek apakah cache masih valid
  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Mengambil semua pengaturan dari API
  Future<Map<String, dynamic>> getAllSettings({
    bool forceRefresh = false,
  }) async {
    // Return cache jika masih valid dan tidak force refresh
    if (_isCacheValid && !forceRefresh) {
      return _settingsCache;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/service/config/get_settings.php'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _settingsCache = Map<String, dynamic>.from(data['data']);
          _lastFetchTime = DateTime.now();
          return _settingsCache;
        }
      }
    } catch (e) {
      print('Error fetching settings: $e');
    }

    return _settingsCache; // Return cache jika gagal
  }

  /// Mengambil nilai pengaturan tertentu
  Future<String?> getSetting(String key, {bool forceRefresh = false}) async {
    final settings = await getAllSettings(forceRefresh: forceRefresh);
    if (settings.containsKey(key)) {
      return settings[key]['value']?.toString();
    }
    return null;
  }

  /// Mengambil lokasi kampus dari pengaturan
  Future<CampusLocation> getCampusLocation({bool forceRefresh = false}) async {
    final settings = await getAllSettings(forceRefresh: forceRefresh);

    // Default values
    double latitude = -7.607453;
    double longitude = 110.792933;
    double radius = 100.0;
    String name = 'SD Islam Al Azhar 28 Solo Baru';

    // Parse dari settings jika ada
    if (settings.containsKey('campus_latitude')) {
      latitude =
          double.tryParse(settings['campus_latitude']['value'] ?? '') ??
          latitude;
    }
    if (settings.containsKey('campus_longitude')) {
      longitude =
          double.tryParse(settings['campus_longitude']['value'] ?? '') ??
          longitude;
    }
    if (settings.containsKey('campus_radius')) {
      radius =
          double.tryParse(settings['campus_radius']['value'] ?? '') ?? radius;
    }
    if (settings.containsKey('campus_name')) {
      name = settings['campus_name']['value'] ?? name;
    }

    return CampusLocation(
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radius,
      name: name,
    );
  }

  /// Mengambil durasi cooldown
  Future<int> getCooldownMinutes({bool forceRefresh = false}) async {
    final value = await getSetting(
      'cooldown_minutes',
      forceRefresh: forceRefresh,
    );
    return int.tryParse(value ?? '') ?? 10;
  }

  /// Clear cache
  void clearCache() {
    _settingsCache = {};
    _lastFetchTime = null;
  }
}

/// Model untuk lokasi kampus
class CampusLocation {
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final String name;

  const CampusLocation({
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.name,
  });

  @override
  String toString() {
    return 'CampusLocation(lat: $latitude, lng: $longitude, radius: $radiusInMeters, name: $name)';
  }
}
