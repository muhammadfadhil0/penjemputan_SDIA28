import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/kelas/kelas_service.dart';
import '../services/kelas/kelas_models.dart';
import '../services/auth/auth_service.dart';
import '../services/emergency/emergency_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// Halaman Riwayat - menampilkan riwayat penjemputan dengan filter tanggal
class KelasRiwayatPage extends StatefulWidget {
  const KelasRiwayatPage({super.key});

  @override
  State<KelasRiwayatPage> createState() => _KelasRiwayatPageState();
}

class _KelasRiwayatPageState extends State<KelasRiwayatPage>
    with SingleTickerProviderStateMixin {
  final KelasService _kelasService = KelasService();
  final AuthService _authService = AuthService();
  final EmergencyService _emergencyService = EmergencyService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  String? _errorMessage;
  List<KelasHistoryItem> _historyItems = [];
  String? _tanggal;
  EmergencyStatus _emergencyStatus = const EmergencyStatus(active: false);
  int _lastHistoryCount = 0;
  bool _hasLoadedOnce = false;

  Timer? _refreshTimer;

  // Filter tanggal
  DateTime? _selectedDate;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterFadeAnimation;
  late Animation<Offset> _filterSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animasi untuk filter
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _filterSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _filterAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadData();
    // Auto refresh setiap 10 detik (hanya jika tidak ada filter)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_selectedDate == null) {
        _loadData(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _filterAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    final user = _authService.currentUser;
    if (user == null || user.kelasId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data kelas tidak ditemukan';
        });
      }
      return;
    }

    final emergencyFuture = _emergencyService.getStatus();
    final response = await _kelasService.getHistory(
      user.kelasId!,
      limit: 100,
      tanggal: _selectedDate,
    );
    final emergencyStatus = await emergencyFuture;

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _historyItems = response.data;
          _tanggal = response.tanggal;
          _errorMessage = null;
          _handleEmergency(emergencyStatus);
        } else {
          _errorMessage = response.message;
          _handleEmergency(emergencyStatus);
        }
        _hasLoadedOnce = true;
      });
    }
  }

  void _handleEmergency(EmergencyStatus status) {
    final currentCount = _historyItems.length;
    final shouldRing = status.active && _hasLoadedOnce && currentCount > _lastHistoryCount;

    _emergencyStatus = status;
    _lastHistoryCount = currentCount;

    if (shouldRing) {
      _playBell();
    }
  }

  Future<void> _playBell() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('web_server/assets/bell, in.MP3'));
    } catch (e) {
      debugPrint('Failed to play bell: $e');
    }
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _filterAnimationController.forward(from: 0);
      _loadData();
    }
  }

  Future<void> _clearFilter() async {
    await _filterAnimationController.reverse();
    setState(() {
      _selectedDate = null;
    });
    _loadData();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: _emergencyStatus.active
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 2,
                  ),
                )
              : null,
          child: Column(
            children: [
              if (_emergencyStatus.active) _buildEmergencyBanner(),
              _buildHeader(),
              // Filter indicator dengan animasi
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedDate != null
                    ? FadeTransition(
                        opacity: _filterFadeAnimation,
                        child: SlideTransition(
                          position: _filterSlideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_alt,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Filter: ${_formatDate(_selectedDate!)}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _clearFilter,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _errorMessage != null
                        ? _buildError()
                        : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    final activatedBy = _emergencyStatus.activatedBy ?? 'Guru';
    final activatedAt = _formatTimestamp(_emergencyStatus.activatedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Mode diaktifkan',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activatedAt != null)
                  Text(
                    '$activatedBy mengaktifkan pada $activatedAt',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatTimestamp(String? timestamp) {
    if (timestamp == null) return null;
    try {
      final dt = DateTime.parse(timestamp);
      const days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$dayName, ${dt.day} $monthName ${dt.year}, $time';
    } catch (_) {
      return timestamp;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: const Icon(
              Icons.history,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDate != null
                      ? 'Riwayat Penjemputan'
                      : 'Riwayat Hari Ini',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : (_tanggal != null
                            ? 'Tanggal $_tanggal'
                            : '${_historyItems.length} penjemputan'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Badge count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_historyItems.length}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Calendar button
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight, width: 1),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Memuat riwayat...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              _selectedDate != null
                  ? 'Tidak ada riwayat pada tanggal ini'
                  : 'Belum ada riwayat penjemputan hari ini',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDate(_selectedDate!),
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _historyItems.length,
        separatorBuilder: (context, index) =>
            Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          return _buildHistoryRow(_historyItems[index], index);
        },
      ),
    );
  }

  Widget _buildHistoryRow(KelasHistoryItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.card),
      child: Row(
        children: [
          // Nomor urut
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryLight, width: 1),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info siswa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama siswa + label panggilan
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.namaAsli,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isMultipleCall) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Text(
                          _getPanggilanLabel(item.panggilanKe),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Penjemput
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.penjemput,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Waktu + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Icon check
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
              const SizedBox(height: 4),
              // Waktu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.waktu,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPanggilanLabel(int panggilanKe) {
    final labels = {
      2: 'Panggilan kedua',
      3: 'Panggilan ketiga',
      4: 'Panggilan keempat',
      5: 'Panggilan kelima',
      6: 'Panggilan keenam',
      7: 'Panggilan ketujuh',
      8: 'Panggilan kedelapan',
      9: 'Panggilan kesembilan',
      10: 'Panggilan kesepuluh',
    };
    return labels[panggilanKe] ?? 'Panggilan ke-$panggilanKe';
  }
}
