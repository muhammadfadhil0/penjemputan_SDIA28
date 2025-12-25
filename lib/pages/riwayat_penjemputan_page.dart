import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';
import '../services/riwayat/riwayat_model.dart';
import '../services/riwayat/riwayat_service.dart';

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

  // State untuk data dari backend
  final RiwayatService _riwayatService = RiwayatService();
  final AuthService _authService = AuthService();
  List<RiwayatPenjemputan> _riwayatData = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination state
  static const int _itemsPerPage = 10;
  int _displayedItemCount = _itemsPerPage;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

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

    // Setup scroll listener untuk pagination
    _scrollController.addListener(_onScroll);

    // Load data saat halaman dibuka
    _loadRiwayatData();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Listener untuk detect scroll ke bawah
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreItems();
    }
  }

  /// Load more items saat scroll ke bawah
  void _loadMoreItems() {
    if (_isLoadingMore) return;
    if (_displayedItemCount >= _filteredData.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulasi delay untuk efek loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayedItemCount = (_displayedItemCount + _itemsPerPage).clamp(
            0,
            _filteredData.length,
          );
          _isLoadingMore = false;
        });
      }
    });
  }

  /// Memuat data riwayat dari backend
  Future<void> _loadRiwayatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _displayedItemCount = _itemsPerPage; // Reset pagination
    });

    // Ambil siswa ID dari AuthService
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Silakan login terlebih dahulu';
      });
      return;
    }

    final result = await _riwayatService.getRiwayatSiswa(
      siswaId: currentUser.id,
      tanggal: _selectedDate,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _riwayatData = result.data;
        // Set initial display count
        _displayedItemCount = _itemsPerPage.clamp(0, _riwayatData.length);
      } else {
        _errorMessage = result.message;
      }
    });
  }

  List<RiwayatPenjemputan> get _filteredData {
    if (_selectedDate == null) {
      return _riwayatData;
    }
    return _riwayatData.where((item) {
      return item.tanggal.year == _selectedDate!.year &&
          item.tanggal.month == _selectedDate!.month &&
          item.tanggal.day == _selectedDate!.day;
    }).toList();
  }

  /// Data yang ditampilkan dengan pagination
  List<RiwayatPenjemputan> get _paginatedData {
    final filtered = _filteredData;
    if (_displayedItemCount >= filtered.length) {
      return filtered;
    }
    return filtered.sublist(0, _displayedItemCount);
  }

  /// Cek apakah masih ada data yang bisa di-load
  bool get _hasMoreData => _displayedItemCount < _filteredData.length;

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
        _displayedItemCount = _itemsPerPage; // Reset pagination saat filter
      });
      _filterAnimationController.forward(from: 0);
      // Reload data dengan filter tanggal
      _loadRiwayatData();
    }
  }

  Future<void> _clearFilter() async {
    await _filterAnimationController.reverse();
    setState(() {
      _selectedDate = null;
      _displayedItemCount = _itemsPerPage; // Reset pagination
    });
    // Reload data tanpa filter
    _loadRiwayatData();
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
          // Content area
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Memuat riwayat...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRiwayatData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_filteredData.isEmpty) {
      return Center(
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
              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'pada tanggal ${_formatDate(_selectedDate!)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Data list dengan pagination
    return RefreshIndicator(
      onRefresh: _loadRiwayatData,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        // +1 untuk loading indicator jika masih ada data
        itemCount: _paginatedData.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator di akhir list
          if (index == _paginatedData.length) {
            return _buildLoadingIndicator();
          }
          return _buildRiwayatCard(_paginatedData[index]);
        },
      ),
    );
  }

  /// Widget loading indicator untuk pagination
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: _isLoadingMore
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Memuat lebih banyak...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              )
            : Text(
                'Menampilkan ${_paginatedData.length} dari ${_filteredData.length} data',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildRiwayatCard(RiwayatPenjemputan data) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;

    switch (data.status) {
      case 'dijemput':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check;
        break;
      case 'dipanggil':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.call;
        break;
      case 'menunggu':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_empty;
        break;
      case 'dibatalkan':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.close;
        break;
      default:
        statusColor = AppColors.textMuted;
        statusIcon = Icons.help_outline;
    }

    // Catatan color
    final bool isPositiveCatatan =
        data.catatan == 'Tepat waktu' || data.status == 'dijemput';

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
                    data.tanggalText.split(' ')[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data.tanggalText.split(' ')[1].length >= 3
                        ? data.tanggalText.split(' ')[1].substring(0, 3)
                        : data.tanggalText.split(' ')[1],
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
                        data.waktu,
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
                      Expanded(
                        child: Text(
                          data.penjemput,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                      color: isPositiveCatatan
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data.catatan,
                      style: TextStyle(
                        color: isPositiveCatatan
                            ? const Color(0xFF10B981)
                            : statusColor,
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
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
