import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';
import '../services/guru/guru_pickup_service.dart';
import '../services/teacher/teacher_service.dart';
import '../widgets/guru_profile_bottomsheet.dart';
import 'package:http/http.dart' as http;
import '../services/emergency/emergency_service.dart';

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
  final TeacherService _teacherService = TeacherService();
  final EmergencyService _emergencyService = EmergencyService();

  // Connection status monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isServerReachable = false;
  bool _isDashboardActive = false;
  String? _activeTeacherName;
  Timer? _connectionCheckTimer;

  // Callback to update bottom sheet modal state (if open)
  void Function(void Function())? _modalStateCallback;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  List<KelasData> _kelasList = [];
  KelasData? _selectedKelas;
  List<StudentForPickup> _searchResults = [];
  StudentForPickup? _selectedStudent;
  bool _isSearching = false;
  bool _isCallingStudent = false;

  // Emergency mode status
  EmergencyStatus _emergencyStatus = const EmergencyStatus(active: false);

  // Picker selection state
  String _selectedPicker = 'ayah';
  String _selectedOjek = 'gojek';
  final TextEditingController _otherPersonController = TextEditingController();
  final TextEditingController _ojekLainnyaController = TextEditingController();

  // Debounce timer for search
  Timer? _debounceTimer;

  // Guru data
  String get guruName => _authService.currentUser?.nama ?? "Guru";

  // Check if all 3 connections are OK
  bool get _isAllConnected =>
      _isConnected && _isServerReachable && _isDashboardActive;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _loadKelasList();
    _loadEmergencyStatus();
    _searchController.addListener(_onSearchChanged);
    _checkExtendedConnectionStatus();
    _startConnectionCheckTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _otherPersonController.dispose();
    _ojekLainnyaController.dispose();
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _connectionCheckTimer?.cancel();
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

  // Start periodic connection status check
  void _startConnectionCheckTimer() {
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkExtendedConnectionStatus(),
    );
  }

  // Check extended connection status (server and dashboard)
  Future<void> _checkExtendedConnectionStatus() async {
    if (!mounted) return;
    final serverReachable = await _checkServerReachable();
    bool dashboardActive = false;
    String? teacherName;
    if (serverReachable) {
      final activeTeacher = await _teacherService.getActiveTeacher();
      if (activeTeacher != null) {
        dashboardActive = true;
        teacherName = activeTeacher.nama;
      }
    }
    if (mounted) {
      setState(() {
        _isServerReachable = serverReachable;
        _isDashboardActive = dashboardActive;
        _activeTeacherName = teacherName;
      });
      // Also update modal if open
      _modalStateCallback?.call(() {});
    }
  }

  // Load emergency mode status from backend
  Future<void> _loadEmergencyStatus() async {
    final status = await _emergencyService.getStatus();
    if (!mounted) return;
    setState(() {
      _emergencyStatus = status;
    });
    _modalStateCallback?.call(() {});
  }

  // Check if server is reachable
  Future<bool> _checkServerReachable() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://soulhbc.com/penjemputan/service/pickup/get_pickup_queue.php',
            ),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
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
    _loadEmergencyStatus();
    _checkExtendedConnectionStatus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        bool isCheckingStatus = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Store callback so timer can update this modal
            _modalStateCallback = setModalState;

            Future<void> refreshStatus() async {
              setModalState(() => isCheckingStatus = true);
              final serverReachable = await _checkServerReachable();
              bool dashboardActive = false;
              String? teacherName;
              if (serverReachable) {
                final activeTeacher = await _teacherService.getActiveTeacher();
                if (activeTeacher != null) {
                  dashboardActive = true;
                  teacherName = activeTeacher.nama;
                }
              }
              final connectivityResult = await _connectivity
                  .checkConnectivity();
              final isConnectedNow =
                  connectivityResult.isNotEmpty &&
                  !connectivityResult.contains(ConnectivityResult.none);
              if (mounted) {
                setState(() {
                  _isConnected = isConnectedNow;
                  _isServerReachable = serverReachable;
                  _isDashboardActive = dashboardActive;
                  _activeTeacherName = teacherName;
                });
              }
              setModalState(() => isCheckingStatus = false);
            }

            Widget buildStatusItem(
              IconData icon,
              String title,
              String subtitle,
              bool isActive,
              bool isLoading,
            ) {
              final color = isLoading
                  ? Colors.grey
                  : (isActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444));
              final bgColor = isLoading
                  ? Colors.grey[100]!
                  : (isActive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2));
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoading ? 'Memeriksa' : subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
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
                  const Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Status Koneksi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  buildStatusItem(
                    Icons.wifi_rounded,
                    'Jaringan Anda',
                    _isConnected ? 'Terhubung' : 'Tidak ada koneksi',
                    _isConnected,
                    isCheckingStatus,
                  ),
                  const SizedBox(height: 12),
                  buildStatusItem(
                    Icons.dns_rounded,
                    'Server Penjemputan',
                    _isServerReachable ? 'Online' : 'Tidak dapat dijangkau',
                    _isServerReachable,
                    isCheckingStatus,
                  ),
                  const SizedBox(height: 12),
                  buildStatusItem(
                    Icons.computer_rounded,
                    'Komputer Kurikulum',
                    _isDashboardActive
                        ? 'Aktif - $_activeTeacherName'
                        : 'Terputus',
                    _isDashboardActive,
                    isCheckingStatus,
                  ),
                  const SizedBox(height: 24),
                  // Emergency Mode Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (_emergencyStatus.active) {
                        _showEmergencyModeDeactivateBottomSheet();
                      } else {
                        _showEmergencyModeBottomSheet();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Emergency Mode',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_emergencyStatus.active)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'AKTIF',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  _emergencyStatus.active
                                      ? 'Matikan mode darurat'
                                      : 'Aktifkan mode darurat',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isCheckingStatus
                              ? null
                              : () => refreshStatus(),
                          icon: isCheckingStatus
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(isCheckingStatus ? 'Tunggu' : 'Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
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
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear callback when modal closes
      _modalStateCallback = null;
    });
  }

  // Show Emergency Mode confirmation bottomsheet
  void _showEmergencyModeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
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
              // Warning Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444), width: 3),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Apa itu Emergency Mode?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              // const SizedBox(height: 12),
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Emergency mode adalah mode dimana data permintaan penjemputan orang tua akan langsung dipanggil menuju halaman penjemputan dengan user kelas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Consequences
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dengan mengaktifkan mode ini:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildEmergencyConsequenceItem(
                '1',
                'Komputer kurikulum penjemputan akan dinonaktifkan',
              ),
              const SizedBox(height: 8),
              _buildEmergencyConsequenceItem(
                '2',
                'Komputer kelas pemanggilan akan dinonaktifkan',
              ),
              const SizedBox(height: 8),
              _buildEmergencyConsequenceItem(
                '3',
                'Pengalihan penjemputan di dalam aplikasi Penjemputan dengan login kelas',
              ),
              const SizedBox(height: 8),
              _buildEmergencyConsequenceItem(
                '4',
                'Anda akan menjadi penanggung jawab penuh atas pengaktifan mode ini, sehingga kami akan menaruh nama Anda sebagai nama pengaktif mode ini',
              ),
              const SizedBox(height: 24),
              // Red Swipe to Confirm
              EmergencySwipeToConfirm(
                text: 'Geser untuk aktifkan',
                onConfirm: () {
                  Navigator.pop(ctx);
                  _activateEmergencyMode();
                },
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _activateEmergencyMode() async {
    final user = _authService.currentUser;
    final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mengaktifkan Emergency Mode...'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    final status = await _emergencyService.activate(
      activatedBy: user?.nama ?? 'Guru',
      activatedById: user?.id,
      activatedByRole: user?.role,
      kelasId: user?.kelasId,
      kelasName: user?.namaKelas,
    );

    await snackbarController.closed;

    if (!mounted) return;

    setState(() {
      _emergencyStatus = status;
    });
    _modalStateCallback?.call(() {});

    final success = status.active;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success
                    ? 'Emergency Mode diaktifkan oleh ${status.activatedBy ?? 'Guru'}'
                    : 'Gagal mengaktifkan Emergency Mode',
              ),
            ),
          ],
        ),
        backgroundColor: success ? Colors.red : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEmergencyModeDeactivateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444), width: 3),
                ),
                child: const Icon(
                  Icons.power_settings_new,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingin menonaktifkan mode darurat?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pemanggilan akan kembali berjalan seperti biasa di komputer kurikulum.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        Navigator.pop(ctx);
                        _deactivateEmergencyMode();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Matikan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deactivateEmergencyMode() async {
    final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Menonaktifkan Emergency Mode...'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    final status = await _emergencyService.deactivate();

    await snackbarController.closed;

    if (!mounted) return;

    setState(() {
      _emergencyStatus = status;
    });
    _modalStateCallback?.call(() {});

    final success = status.active == false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Emergency Mode dinonaktifkan',
              ),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildEmergencyConsequenceItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ),
      ],
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
                                  ? Builder(
                                      builder: (context) {
                                        final url =
                                            _authService.currentUser!.fotoUrl!;
                                        final fullUrl = url.startsWith('http')
                                            ? url
                                            : 'https://soulhbc.com/penjemputan/$url';

                                        return Image.network(
                                          fullUrl,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.person_rounded,
                                                    color:
                                                        Colors.amber.shade700,
                                                    size: 32,
                                                  ),
                                        );
                                      },
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
                        color: _isAllConnected
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAllConnected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isAllConnected
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        color: _isAllConnected
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

// ============================================
// EMERGENCY SWIPE TO CONFIRM WIDGET (Red Theme)
// ============================================
class EmergencySwipeToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;

  const EmergencySwipeToConfirm({
    super.key,
    required this.text,
    required this.onConfirm,
  });

  @override
  State<EmergencySwipeToConfirm> createState() =>
      _EmergencySwipeToConfirmState();
}

class _EmergencySwipeToConfirmState extends State<EmergencySwipeToConfirm>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  double _containerWidth = 0;
  bool _isConfirmed = false;
  late AnimationController _shimmerController;

  static const double _thumbSize = 52;
  static const double _padding = 4;

  // Emergency red colors
  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _darkRed = Color(0xFFDC2626);
  static const Color _lightRed = Color(0xFFFEE2E2);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  double get _maxDragDistance => _containerWidth - _thumbSize - (_padding * 2);
  double get _dragPercentage => _maxDragDistance > 0
      ? (_dragPosition / _maxDragDistance).clamp(0.0, 1.0)
      : 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isConfirmed) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(
        0.0,
        _maxDragDistance,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isConfirmed) return;

    if (_dragPercentage > 0.85) {
      // Confirmation success
      setState(() {
        _dragPosition = _maxDragDistance;
        _isConfirmed = true;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onConfirm();
      });
    } else {
      // Animate back to start
      _animateBack();
    }
  }

  void _animateBack() {
    const duration = Duration(milliseconds: 400);
    final startPosition = _dragPosition;

    Future<void> animate() async {
      const steps = 20;
      for (int i = 0; i <= steps; i++) {
        await Future.delayed(duration ~/ steps);
        if (!mounted) return;

        final t = i / steps;
        final curve = Curves.easeOutBack.transform(t);

        setState(() {
          _dragPosition = startPosition * (1 - curve);
        });
      }
    }

    animate();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: _isConfirmed ? _darkRed : _lightRed,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isConfirmed ? _darkRed : _primaryRed.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isConfirmed
                    ? _darkRed.withOpacity(0.3)
                    : _primaryRed.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition + _thumbSize + _padding,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isConfirmed
                        ? [_darkRed, _primaryRed]
                        : [
                            _primaryRed.withOpacity(0.3),
                            _primaryRed.withOpacity(0.4),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),

              // Text with shimmer effect
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isConfirmed ? 0 : (1 - _dragPercentage * 0.5),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: const [
                              _darkRed,
                              Color(0xFFB91C1C),
                              _darkRed,
                            ],
                            stops: [
                              (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                              _shimmerController.value,
                              (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Confirmed text
              if (_isConfirmed)
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Mengaktifkan..',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // Draggable thumb
              Positioned(
                left: _padding + _dragPosition,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: _isConfirmed ? Colors.white : _primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isConfirmed ? _darkRed : _primaryRed)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isConfirmed
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                        color: _isConfirmed ? _darkRed : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
