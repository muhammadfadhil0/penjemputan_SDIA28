import 'package:flutter/material.dart';
import '../main.dart';
import '../services/jadwal/jadwal_model.dart';
import '../services/jadwal/jadwal_service.dart';
import '../services/auth/auth_service.dart';

// ============================================
// JADWAL PAGE
// ============================================

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final JadwalService _jadwalService = JadwalService();

  bool _isLoading = true;
  String? _errorMessage;
  List<JadwalItem> _jadwalList = [];
  int? _currentKelasId;

  @override
  void initState() {
    super.initState();
    _initJadwal();
  }

  /// Inisialisasi jadwal - gunakan cache jika tersedia
  Future<void> _initJadwal() async {
    // Pastikan user session ter-load
    final authService = AuthService();
    await authService.loadStoredUser();
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Silakan login terlebih dahulu';
      });
      return;
    }

    _currentKelasId = user.kelasId;

    // Cek apakah ada data di cache
    final cachedJadwal = _jadwalService.getCachedJadwal(user.kelasId);
    if (cachedJadwal != null) {
      // Gunakan data dari cache
      setState(() {
        _jadwalList = cachedJadwal.jadwalList;
        _isLoading = false;
      });
      return;
    }

    // Tidak ada cache, load dari server
    await _loadJadwal();
  }

  /// Load jadwal dari server (called on init jika tidak ada cache, atau saat refresh)
  Future<void> _loadJadwal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pastikan user session ter-load jika belum
      if (_currentKelasId == null) {
        final authService = AuthService();
        await authService.loadStoredUser();
        final user = authService.currentUser;

        if (user == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Silakan login terlebih dahulu';
          });
          return;
        }
        _currentKelasId = user.kelasId;
      }

      // Ambil jadwal dari server
      final result = await _jadwalService.getJadwalByKelas(_currentKelasId!);

      if (result.success && result.jadwal != null) {
        // Simpan ke cache
        _jadwalService.cacheJadwal(_currentKelasId!, result.jadwal!);

        setState(() {
          _jadwalList = result.jadwal!.jadwalList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jadwal',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Refresh button
                  AnimatedScaleOnTap(
                    onTap: _loadJadwal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: _isLoading
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jadwal penjemputan minggu ini',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Schedule list
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_jadwalList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadJadwal,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _jadwalList.length,
        itemBuilder: (context, index) {
          final jadwal = _jadwalList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JadwalCard(jadwal: jadwal, index: index),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _JadwalCardSkeleton(),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal Memuat Jadwal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            AnimatedScaleOnTap(
              onTap: _loadJadwal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Coba Lagi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada jadwal',
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// Skeleton card for loading state
class _JadwalCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Day icon skeleton
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Time skeleton
          Container(
            width: 70,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Schedule Card dengan Hero Animation
class JadwalCard extends StatelessWidget {
  final JadwalItem jadwal;
  final int index;

  const JadwalCard({super.key, required this.jadwal, required this.index});

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => JadwalDetailBottomSheet(jadwal: jadwal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleOnTap(
      onTap: () => _showDetailBottomSheet(context),
      scaleDown: 0.97,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: jadwal.isHoliday
              ? const Color(0xFFFEF3C7) // Amber-100 for holiday
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: jadwal.isHoliday
                ? const Color(0xFFFCD34D) // Amber-300 for holiday
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: jadwal.isHoliday
                    ? const Color(0xFFFBBF24) // Amber-400
                    : jadwal.isToday
                    ? AppColors.primary
                    : AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: jadwal.isHoliday
                    ? const Text('🌴', style: TextStyle(fontSize: 20))
                    : Text(
                        jadwal.dayShort,
                        style: TextStyle(
                          color: jadwal.isToday
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        jadwal.hari,
                        style: TextStyle(
                          color: jadwal.isHoliday
                              ? const Color(0xFF92400E)
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (jadwal.isToday && !jadwal.isHoliday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (jadwal.isHoliday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LIBUR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jadwal.isHoliday ? 'Tidak ada sekolah' : 'Pulang sekolah',
                    style: TextStyle(
                      color: jadwal.isHoliday
                          ? const Color(0xFFB45309)
                          : AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: jadwal.isHoliday
                    ? const Color(0xFFFDE68A)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: jadwal.isHoliday
                      ? const Color(0xFFFBBF24)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: jadwal.isHoliday
                        ? const Color(0xFF92400E)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    jadwal.isHoliday ? '-' : jadwal.jamKeluar,
                    style: TextStyle(
                      color: jadwal.isHoliday
                          ? const Color(0xFF92400E)
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Detail BottomSheet
class JadwalDetailBottomSheet extends StatelessWidget {
  final JadwalItem jadwal;

  const JadwalDetailBottomSheet({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final isHoliday = jadwal.isHoliday;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 70),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with day icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isHoliday
                        ? const Color(0xFFFBBF24)
                        : jadwal.isToday
                        ? AppColors.primary
                        : AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: jadwal.isToday && !isHoliday
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isHoliday
                        ? const Text('🌴', style: TextStyle(fontSize: 32))
                        : Text(
                            jadwal.dayShort,
                            style: TextStyle(
                              color: jadwal.isToday
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  jadwal.hari,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (jadwal.isToday && !isHoliday) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Hari Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isHoliday) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'HARI LIBUR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // Jam Masuk & Keluar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isHoliday
                        ? const Color(0xFFFEF3C7)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHoliday
                          ? const Color(0xFFFCD34D)
                          : AppColors.border,
                    ),
                  ),
                  child: isHoliday
                      ? Column(
                          children: [
                            const Text('🌴', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak Ada Sekolah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hari ini ditandai sebagai hari libur',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // Jam Masuk
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.login_rounded,
                                      color: Color(0xFF16A34A),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Jam Masuk',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    jadwal.jamMasuk,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Divider
                            Container(
                              height: 80,
                              width: 1,
                              color: AppColors.border,
                            ),
                            // Jam Keluar
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Jam Keluar',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    jadwal.jamKeluar,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: AnimatedScaleOnTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tutup',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
