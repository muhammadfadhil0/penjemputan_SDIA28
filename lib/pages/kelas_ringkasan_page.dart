import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/kelas/kelas_service.dart';
import '../services/kelas/kelas_models.dart';
import '../services/auth/auth_service.dart';
import '../services/emergency/emergency_service.dart';
import '../widgets/guru_profile_bottomsheet.dart';
import 'package:audioplayers/audioplayers.dart';

/// Halaman Ringkasan - menampilkan grid siswa dengan status penjemputan
class KelasRingkasanPage extends StatefulWidget {
  const KelasRingkasanPage({super.key});

  @override
  State<KelasRingkasanPage> createState() => _KelasRingkasanPageState();
}

class _KelasRingkasanPageState extends State<KelasRingkasanPage> {
  final KelasService _kelasService = KelasService();
  final AuthService _authService = AuthService();
  final EmergencyService _emergencyService = EmergencyService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  String? _errorMessage;
  KelasInfo? _kelasInfo;
  KelasStatistik? _statistik;
  List<KelasStudent> _students = [];
  EmergencyStatus _emergencyStatus = const EmergencyStatus(active: false);
  int _lastPickedUpCount = 0;
  bool _hasLoadedOnce = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto refresh setiap 10 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
    final response = await _kelasService.getStudents(user.kelasId!);
    final emergencyStatus = await emergencyFuture;

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _kelasInfo = response.kelas;
          _statistik = response.statistik;
          _students = response.students;
          _errorMessage = null;

          _handleEmergencyStatus(emergencyStatus);
        } else {
          _errorMessage = response.message;
          _handleEmergencyStatus(emergencyStatus);
        }
        _hasLoadedOnce = true;
      });
    }
  }

  void _handleEmergencyStatus(EmergencyStatus status) {
    final pickedUp = _statistik?.sudahDijemput ?? 0;
    final shouldRing =
        status.active && _hasLoadedOnce && pickedUp > _lastPickedUpCount;

    _emergencyStatus = status;
    _lastPickedUpCount = pickedUp;

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
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _errorMessage != null
                    ? _buildError()
                    : _buildStudentGrid(),
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
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
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
        'Minggu',
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
        'Des',
      ];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$dayName, ${dt.day} $monthName ${dt.year}, $time';
    } catch (_) {
      return timestamp;
    }
  }

  Widget _buildHeader() {
    final namaKelas =
        _kelasInfo?.namaKelas ?? _authService.currentUser?.namaKelas ?? 'Kelas';
    final total = _statistik?.total ?? 0;
    final dijemput = _statistik?.sudahDijemput ?? 0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Clickable icon for account switching
              GestureDetector(
                onTap: () => showGuruProfileBottomSheet(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Icon(
                    Icons.class_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaKelas,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status penjemputan • $total Siswa',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          _buildProgressBar(dijemput, total),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int dijemput, int total) {
    final progress = total == 0 ? 0.0 : dijemput / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$dijemput dari $total sudah dijemput',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF10B981), // success green
            ),
          ),
        ),
      ],
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
            'Memuat data siswa...',
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

  Widget _buildStudentGrid() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Tidak ada siswa di kelas ini',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          return _buildStudentCard(_students[index], index);
        },
      ),
    );
  }

  Widget _buildStudentCard(KelasStudent student, int index) {
    final isDijemput = student.sudahDijemput;

    return GestureDetector(
      onTap: () => _showStudentDetail(student),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200 + (index * 30)),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          gradient: isDijemput
              ? const LinearGradient(
                  colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDijemput
                ? const Color(0xFF34D399)
                : const Color(0xFFD1D5DB),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar dengan foto profil
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDijemput
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
                border: isDijemput
                    ? Border.all(color: const Color(0xFF10B981), width: 2)
                    : null,
              ),
              child: ClipOval(
                child: student.fotoUrl != null && student.fotoUrl!.isNotEmpty
                    ? Stack(
                        children: [
                          Image.network(
                            student.fotoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: isDijemput
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : Text(
                                        student.inisial,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                              );
                            },
                          ),
                          // Overlay checkmark untuk siswa yang sudah dijemput
                          if (isDijemput)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.7),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: isDijemput
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                student.inisial,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Nama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                student.namaPanggilan,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDijemput
                      ? const Color(0xFF065F46)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isDijemput) ...[
              const SizedBox(height: 4),
              Text(
                'Dijemput',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF059669),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStudentDetail(KelasStudent student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _StudentDetailBottomSheet(student: student),
    );
  }
}

/// Bottom sheet untuk detail siswa
class _StudentDetailBottomSheet extends StatelessWidget {
  final KelasStudent student;

  const _StudentDetailBottomSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    final isDijemput = student.sudahDijemput;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar besar dengan foto profil
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDijemput
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDijemput
                          ? const Color(0xFF34D399)
                          : const Color(0xFFD1D5DB),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        student.fotoUrl != null && student.fotoUrl!.isNotEmpty
                        ? Stack(
                            children: [
                              Image.network(
                                student.fotoUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: isDijemput
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF10B981),
                                            size: 40,
                                          )
                                        : Text(
                                            student.inisial,
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                  );
                                },
                              ),
                              // Overlay checkmark untuk siswa yang sudah dijemput
                              if (isDijemput)
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.7),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: isDijemput
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF10B981),
                                    size: 40,
                                  )
                                : Text(
                                    student.inisial,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nama lengkap
                Text(
                  student.nama,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Nama panggilan
                if (student.namaPanggilan != student.nama)
                  Text(
                    '(${student.namaPanggilan})',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 20),
                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDijemput
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDijemput
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDijemput
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            color: isDijemput
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDijemput ? 'Sudah Dijemput' : 'Menunggu Dijemput',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDijemput
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      if (isDijemput && student.waktuDijemput != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Jam ${student.waktuDijemput}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isDijemput && student.penjemput != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Dijemput oleh: ${student.penjemput}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol tutup
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
