import 'package:flutter/material.dart';
import '../main.dart';

// ============================================
// RIWAYAT PENJEMPUTAN PAGE
// ============================================
class RiwayatPenjemputanPage extends StatefulWidget {
  const RiwayatPenjemputanPage({super.key});

  @override
  State<RiwayatPenjemputanPage> createState() => _RiwayatPenjemputanPageState();
}

class _RiwayatPenjemputanPageState extends State<RiwayatPenjemputanPage>
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterFadeAnimation;
  late Animation<Offset> _filterSlideAnimation;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  // Dummy data untuk riwayat penjemputan
  static final List<Map<String, dynamic>> _riwayatData = [
    {
      'tanggal': DateTime(2024, 12, 20),
      'tanggalText': '20 Desember 2024',
      'waktu': '14:30',
      'penjemput': 'Ayah',
      'status': 'Selesai',
      'catatan': 'Tepat waktu',
    },
    {
      'tanggal': DateTime(2024, 12, 19),
      'tanggalText': '19 Desember 2024',
      'waktu': '14:15',
      'penjemput': 'Ibu',
      'status': 'Selesai',
      'catatan': 'Tepat waktu',
    },
    {
      'tanggal': DateTime(2024, 12, 18),
      'tanggalText': '18 Desember 2024',
      'waktu': '15:00',
      'penjemput': 'Kakek',
      'status': 'Selesai',
      'catatan': 'Terlambat 30 menit',
    },
    {
      'tanggal': DateTime(2024, 12, 17),
      'tanggalText': '17 Desember 2024',
      'waktu': '14:25',
      'penjemput': 'Ayah',
      'status': 'Selesai',
      'catatan': 'Tepat waktu',
    },
    {
      'tanggal': DateTime(2024, 12, 16),
      'tanggalText': '16 Desember 2024',
      'waktu': '14:45',
      'penjemput': 'Nenek',
      'status': 'Selesai',
      'catatan': 'Tepat waktu',
    },
    {
      'tanggal': DateTime(2024, 12, 13),
      'tanggalText': '13 Desember 2024',
      'waktu': '14:20',
      'penjemput': 'Ibu',
      'status': 'Selesai',
      'catatan': 'Tepat waktu',
    },
    {
      'tanggal': DateTime(2024, 12, 12),
      'tanggalText': '12 Desember 2024',
      'waktu': '14:35',
      'penjemput': 'Ayah',
      'status': 'Selesai',
      'catatan': 'Tepat waktu',
    },
  ];

  List<Map<String, dynamic>> get _filteredData {
    if (_selectedDate == null) {
      return _riwayatData;
    }
    return _riwayatData.where((item) {
      final DateTime itemDate = item['tanggal'];
      return itemDate.year == _selectedDate!.year &&
          itemDate.month == _selectedDate!.month &&
          itemDate.day == _selectedDate!.day;
    }).toList();
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
    }
  }

  Future<void> _clearFilter() async {
    await _filterAnimationController.reverse();
    setState(() {
      _selectedDate = null;
    });
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
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Penjemputan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Calendar button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showDatePicker,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter indicator with animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _selectedDate != null
                ? FadeTransition(
                    opacity: _filterFadeAnimation,
                    child: SlideTransition(
                      position: _filterSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: ShadcnCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
          // List Riwayat
          Expanded(
            child: _filteredData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada riwayat penjemputan',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'pada tanggal ${_formatDate(_selectedDate!)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      return _buildRiwayatCard(_filteredData[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> data) {
    final bool isTepat = data['catatan'] == 'Tepat waktu';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadcnCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['tanggalText'].split(' ')[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data['tanggalText'].split(' ')[1].substring(0, 3),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['waktu'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.person,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['penjemput'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTepat
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data['catatan'],
                      style: TextStyle(
                        color: isTepat
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
