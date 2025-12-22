import 'package:flutter/material.dart';
import '../main.dart';

// ============================================
// JADWAL PAGE
// ============================================

// Model untuk data jadwal
class JadwalData {
  final String day;
  final String dayShort;
  final String jamMasuk;
  final String jamKeluar;
  final bool isToday;

  const JadwalData({
    required this.day,
    required this.dayShort,
    required this.jamMasuk,
    required this.jamKeluar,
    this.isToday = false,
  });
}

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  static final List<JadwalData> jadwalList = [
    JadwalData(
      day: 'Senin',
      dayShort: 'Se',
      jamMasuk: '07:00',
      jamKeluar: '14:00',
      isToday: true,
    ),
    JadwalData(
      day: 'Selasa',
      dayShort: 'Se',
      jamMasuk: '07:00',
      jamKeluar: '14:30',
    ),
    JadwalData(
      day: 'Rabu',
      dayShort: 'Ra',
      jamMasuk: '07:00',
      jamKeluar: '13:00',
    ),
    JadwalData(
      day: 'Kamis',
      dayShort: 'Ka',
      jamMasuk: '07:00',
      jamKeluar: '14:00',
    ),
    JadwalData(
      day: 'Jumat',
      dayShort: 'Ju',
      jamMasuk: '07:00',
      jamKeluar: '11:30',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Jadwal',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: jadwalList.length,
                itemBuilder: (context, index) {
                  final jadwal = jadwalList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: JadwalCard(jadwal: jadwal, index: index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Schedule Card dengan Hero Animation
class JadwalCard extends StatelessWidget {
  final JadwalData jadwal;
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
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
                color: jadwal.isToday
                    ? AppColors.primary
                    : AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  jadwal.day.substring(0, 2),
                  style: TextStyle(
                    color: jadwal.isToday ? Colors.white : AppColors.primary,
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
                  Text(
                    jadwal.day,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pulang sekolah',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    jadwal.jamKeluar,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
  final JadwalData jadwal;

  const JadwalDetailBottomSheet({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
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
                    color: jadwal.isToday
                        ? AppColors.primary
                        : AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: jadwal.isToday
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
                    child: Text(
                      jadwal.day.substring(0, 2),
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
                  jadwal.day,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (jadwal.isToday) ...[
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
                const SizedBox(height: 28),
                // Jam Masuk & Keluar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
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
                      Container(height: 80, width: 1, color: AppColors.border),
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
