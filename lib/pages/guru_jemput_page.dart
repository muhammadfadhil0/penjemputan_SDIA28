import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';
import '../services/guru/guru_pickup_service.dart';
import '../widgets/guru_profile_bottomsheet.dart';

// ============================================
// GURU PICKUP DASHBOARD PAGE
// ============================================
class GuruPickupDashboardPage extends StatefulWidget {
  const GuruPickupDashboardPage({super.key});

  @override
  State<GuruPickupDashboardPage> createState() =>
      _GuruPickupDashboardPageState();
}

class _GuruPickupDashboardPageState extends State<GuruPickupDashboardPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final GuruPickupService _guruPickupService = GuruPickupService();

  // Connection status monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  List<KelasData> _kelasList = [];
  KelasData? _selectedKelas;
  List<StudentForPickup> _searchResults = [];
  StudentForPickup? _selectedStudent;
  bool _isSearching = false;
  bool _isCallingStudent = false;

  // Picker selection state
  String _selectedPicker = 'ayah';
  String _selectedOjek = 'gojek';
  final TextEditingController _otherPersonController = TextEditingController();
  final TextEditingController _ojekLainnyaController = TextEditingController();

  // Debounce timer for search
  Timer? _debounceTimer;

  // Guru data
  String get guruName => _authService.currentUser?.nama ?? "Guru";

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _loadKelasList();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _otherPersonController.dispose();
    _ojekLainnyaController.dispose();
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Initialize connectivity check
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  // Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (!mounted) return;
    setState(() {
      _isConnected =
          result.isNotEmpty && !result.contains(ConnectivityResult.none);
    });
  }

  // Load list of classes
  Future<void> _loadKelasList() async {
    final kelasList = await _guruPickupService.getKelasList();
    if (mounted) {
      setState(() {
        _kelasList = kelasList;
      });
    }
  }

  // Handle search text changes with debounce
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  // Perform search
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty && _selectedKelas == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _guruPickupService.searchStudents(
      query: query.isNotEmpty ? query : null,
      kelasId: _selectedKelas?.id,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  // Select a student
  void _selectStudent(StudentForPickup student) {
    setState(() {
      _selectedStudent = student;
    });
  }

  // Clear selected student
  void _clearSelectedStudent() {
    setState(() {
      _selectedStudent = null;
      // Reset picker selection
      _selectedPicker = 'ayah';
      _selectedOjek = 'gojek';
      _otherPersonController.clear();
      _ojekLainnyaController.clear();
    });
  }

  // Get penjemput detail based on selection
  String? _getPenjemputDetail() {
    if (_selectedPicker == 'ojek') {
      if (_selectedOjek == 'lainnya') {
        return _ojekLainnyaController.text.isNotEmpty
            ? _ojekLainnyaController.text
            : null;
      }
      return _selectedOjek; // gojek, grab, maxim
    } else if (_selectedPicker == 'lainnya') {
      return _otherPersonController.text.isNotEmpty
          ? _otherPersonController.text
          : null;
    }
    return null;
  }

  // Call selected student for pickup
  Future<void> _callStudent() async {
    if (_selectedStudent == null) return;

    setState(() => _isCallingStudent = true);

    // Format penjemput string for display
    String penjemputDisplay = _selectedPicker;
    final detail = _getPenjemputDetail();
    if (detail != null) {
      penjemputDisplay = '$_selectedPicker ($detail)';
    }

    final result = await _guruPickupService.callStudentForPickup(
      siswaId: _selectedStudent!.id,
      calledByGuruName: guruName,
      penjemput: _selectedPicker,
      catatan: detail,
    );

    if (mounted) {
      setState(() => _isCallingStudent = false);

      // Show result snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.success
                      ? '${_selectedStudent!.displayName} berhasil dipanggil! (Penjemput: $penjemputDisplay)'
                      : result.message,
                ),
              ),
            ],
          ),
          backgroundColor: result.success ? AppColors.primary : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

      if (result.success) {
        // Clear selection and refresh search results
        _clearSelectedStudent();
        _performSearch();
      }
    }
  }

  // Show confirmation bottom sheet before calling
  void _showCallConfirmationBottomSheet() {
    if (_selectedStudent == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Student avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: ClipOval(
                  child: _selectedStudent!.fotoUrl != null
                      ? Image.network(
                          _selectedStudent!.fotoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Panggil ${_selectedStudent!.displayName}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedStudent!.namaKelas,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Siswa akan dipanggil untuk penjemputan dan muncul di daftar antrian.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _callStudent();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Panggil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  // Handle connection status tap
  void _handleConnectionStatusTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isConnected
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isConnected
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                  width: 3,
                ),
              ),
              child: Icon(
                _isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: _isConnected
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isConnected ? 'Koneksi Anda stabil' : 'Jaringan tidak stabil',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isConnected
                  ? 'Kami mendeteksi koneksi Anda stabil'
                  : 'Jaringan tidak stabil dapat menyebabkan kegagalan pengiriman data',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Header dengan profil guru
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Guru avatar - tap to show profile bottom sheet
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showGuruProfileBottomSheet(context),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.amber.shade400,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _authService.currentUser?.fotoUrl != null
                                  ? Image.network(
                                      _authService.currentUser!.fotoUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.person_rounded,
                                            color: Colors.amber.shade700,
                                            size: 32,
                                          ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      color: Colors.amber.shade700,
                                      size: 32,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  guruName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    'Guru Piket',
                                    style: TextStyle(
                                      color: Colors.amber.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _handleConnectionStatusTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isConnected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isConnected
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        color: _isConnected
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Panggil Siswa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cari dan pilih siswa untuk dipanggil',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama siswa...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Class filter dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<KelasData?>(
                        value: _selectedKelas,
                        isExpanded: true,
                        hint: const Text(
                          'Semua Kelas',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                        items: [
                          const DropdownMenuItem<KelasData?>(
                            value: null,
                            child: Text('Semua Kelas'),
                          ),
                          ..._kelasList.map(
                            (kelas) => DropdownMenuItem(
                              value: kelas,
                              child: Text(kelas.nama),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedKelas = value;
                          });
                          _performSearch();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Results
            Expanded(child: _buildSearchResults()),

            // Selected Student Card & Call Button
            if (_selectedStudent != null) _buildSelectedStudentCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isEmpty && _selectedKelas == null) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cari siswa untuk memulai',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ketik nama atau pilih kelas',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_rounded,
                size: 64,
                color: AppColors.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada siswa ditemukan',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final student = _searchResults[index];
        final isSelected = _selectedStudent?.id == student.id;

        return GestureDetector(
          onTap: () => _selectStudent(student),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLighter : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Student avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: student.fotoUrl != null
                        ? Image.network(
                            student.fotoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.textMuted,
                                  size: 24,
                                ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.nama,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.namaKelas,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.7)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                if (student.hasActiveRequest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      student.currentStatus == 'menunggu'
                          ? 'Antre'
                          : 'Dipanggil',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  )
                else if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedStudentCard() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected student info row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _selectedStudent!.fotoUrl != null
                      ? Image.network(
                          _selectedStudent!.fotoUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedStudent!.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedStudent!.namaKelas,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _clearSelectedStudent,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Picker selection
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dijemput oleh:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPickerSegments(),

          // Ojek sub-selector
          if (_selectedPicker == 'ojek') ...[
            const SizedBox(height: 8),
            _buildOjekSubSelector(),
          ],

          // Ojek lainnya input
          if (_selectedPicker == 'ojek' && _selectedOjek == 'lainnya') ...[
            const SizedBox(height: 8),
            _buildPickerTextField(
              controller: _ojekLainnyaController,
              hint: 'Nama ojek lainnya',
              icon: Icons.two_wheeler,
            ),
          ],

          // Other person input
          if (_selectedPicker == 'lainnya') ...[
            const SizedBox(height: 8),
            _buildPickerTextField(
              controller: _otherPersonController,
              hint: 'Nama penjemput',
              icon: Icons.person_outline,
            ),
          ],

          const SizedBox(height: 12),

          // Call button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCallingStudent
                  ? null
                  : _showCallConfirmationBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCallingStudent
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Panggil Siswa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerSegments() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildPickerSegmentItem('ayah', 'Ayah', Icons.man),
          _buildPickerSegmentItem('ibu', 'Ibu', Icons.woman),
          _buildPickerSegmentItem('ojek', 'Ojek', Icons.two_wheeler),
          _buildPickerSegmentItem('lainnya', 'Lainnya', Icons.people),
        ],
      ),
    );
  }

  Widget _buildPickerSegmentItem(String value, String label, IconData icon) {
    final isSelected = _selectedPicker == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPicker = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOjekSubSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _buildOjekItem('gojek', 'Gojek'),
          _buildOjekItem('grab', 'Grab'),
          _buildOjekItem('maxim', 'Maxim'),
          _buildOjekItem('lainnya', 'Lainnya'),
        ],
      ),
    );
  }

  Widget _buildOjekItem(String value, String label) {
    final isSelected = _selectedOjek == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedOjek = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
        ),
      ),
    );
  }
}
