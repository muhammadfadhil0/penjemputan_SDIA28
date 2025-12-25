import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';

// ============================================
// PICKUP DASHBOARD PAGE
// ============================================
class PickupDashboardPage extends StatefulWidget {
  const PickupDashboardPage({super.key});

  @override
  State<PickupDashboardPage> createState() => _PickupDashboardPageState();
}

class _PickupDashboardPageState extends State<PickupDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  final AuthService _authService = AuthService();

  // Data siswa dari hasil login
  String get studentName => _authService.currentUser?.displayName ?? "Siswa";
  String get studentClass =>
      "Kelas ${_authService.currentUser?.namaKelas ?? ""}";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _showPickupBottomSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: const Material(
              color: Colors.transparent,
              child: PickupBottomSheet(),
            ),
          ),
        );
      },
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

            // Header dengan profil siswa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: AppColors.primaryLighter,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          studentName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          studentClass,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Guru Penjaga Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ShadcnCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_pin_rounded,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saat ini guru yang bertugas',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Siri Rofikah S.Pd',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Main Pickup Button (dengan animasi)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer rotating dashed circle
                          AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotateController.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(260, 260),
                                  painter: DashedCirclePainter(
                                    color: AppColors.border,
                                    strokeWidth: 2,
                                    dashLength: 8,
                                    gapLength: 6,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Inner rotating dashed circle (reverse)
                          AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: -_rotateController.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(230, 230),
                                  painter: DashedCirclePainter(
                                    color: AppColors.primaryLight.withValues(
                                      alpha: 0.4,
                                    ),
                                    strokeWidth: 1.5,
                                    dashLength: 12,
                                    gapLength: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Main button with pulse
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: AnimatedScaleOnTap(
                              onTap: _showPickupBottomSheet,
                              scaleDown: 0.92,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.card,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_car_rounded,
                                      color: AppColors.primary,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'JEMPUT',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
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
              ),
            ),

            // Bottom hint
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tekan tombol untuk meminta jemput',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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

// ============================================
// DASHED CIRCLE PAINTER
// ============================================
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashLength + gapLength)) / radius;
      final sweepAngle = dashLength / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// PICKUP BOTTOM SHEET
// ============================================
class PickupBottomSheet extends StatefulWidget {
  const PickupBottomSheet({super.key});

  @override
  State<PickupBottomSheet> createState() => _PickupBottomSheetState();
}

class _PickupBottomSheetState extends State<PickupBottomSheet> {
  String _selectedPicker = 'ayah';
  String _selectedOjek = 'gojek';
  String _selectedArrival = 'tiba'; // 'tiba' or 'akan_tiba'
  TimeOfDay? _estimatedTime;
  final TextEditingController _otherPersonController = TextEditingController();
  final TextEditingController _ojekLainnyaController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _otherPersonController.dispose();
    _ojekLainnyaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _estimatedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _estimatedTime = picked;
      });
    }
  }

  void _submitRequest() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Permintaan jemput berhasil dikirim!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  'Permintaan Penjemputan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Section 1: Dijemput oleh siapa
              _buildLabel('Ananda dijemput oleh siapa?'),
              const SizedBox(height: 10),
              _buildSegmentedButton(),

              // Ojek sub-selector
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedPicker == 'ojek'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildOjekSubSelector(),
                      )
                    : const SizedBox.shrink(),
              ),

              // Ojek lainnya input
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedPicker == 'ojek' && _selectedOjek == 'lainnya'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTextField(
                          controller: _ojekLainnyaController,
                          hint: 'Nama ojek online lainnya',
                          icon: Icons.two_wheeler,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Other person input
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedPicker == 'lainnya'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTextField(
                          controller: _otherPersonController,
                          hint: 'Nama orang yang menjemput',
                          icon: Icons.person_outline,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Section 2: Estimasi waktu
              _buildLabel('Estimasi Anda sampai sekolah?'),
              const SizedBox(height: 10),
              _buildArrivalSegmentedButton(),

              // Time input for "akan tiba"
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _selectedArrival == 'akan_tiba'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTimeSelector(),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  int get _pickerIndex {
    switch (_selectedPicker) {
      case 'ayah':
        return 0;
      case 'ibu':
        return 1;
      case 'ojek':
        return 2;
      case 'lainnya':
        return 3;
      default:
        return 0;
    }
  }

  final List<String> _pickerOptions = ['ayah', 'ibu', 'ojek', 'lainnya'];

  void _handlePickerSwipe(DragEndDetails details, double containerWidth) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      // Swipe detected
      if (velocity > 0 && _pickerIndex > 0) {
        // Swipe right - go to previous
        setState(() => _selectedPicker = _pickerOptions[_pickerIndex - 1]);
      } else if (velocity < 0 && _pickerIndex < 3) {
        // Swipe left - go to next
        setState(() => _selectedPicker = _pickerOptions[_pickerIndex + 1]);
      }
    }
  }

  void _handlePickerDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 4;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 3);

    if (newIndex != _pickerIndex) {
      setState(() => _selectedPicker = _pickerOptions[newIndex]);
    }
  }

  Widget _buildSegmentedButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / 4;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _handlePickerDragUpdate(details, constraints.maxWidth),
            onHorizontalDragEnd: (details) =>
                _handlePickerSwipe(details, constraints.maxWidth),
            child: Stack(
              children: [
                // Sliding indicator with bounce
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: _pickerIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Items
                Row(
                  children: [
                    _buildSegmentItem('ayah', 'Ayah', Icons.man),
                    _buildSegmentItem('ibu', 'Ibu', Icons.woman),
                    _buildSegmentItem('ojek', 'Ojek', Icons.two_wheeler),
                    _buildSegmentItem('lainnya', 'Lainnya', Icons.people),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOjekSubSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildOjekItem('gojek', 'Gojek'),
              _buildOjekItem('grab', 'Grab'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildOjekItem('maxim', 'Maxim'),
              _buildOjekItem('lainnya', 'Lainya'),
            ],
          ),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem(String value, String label, IconData icon) {
    final isSelected = _selectedPicker == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPicker = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'MaterialIcons',
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _arrivalIndex {
    return _selectedArrival == 'tiba' ? 0 : 1;
  }

  final List<String> _arrivalOptions = ['tiba', 'akan_tiba'];

  void _handleArrivalSwipe(DragEndDetails details, double containerWidth) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      // Swipe detected
      if (velocity > 0 && _arrivalIndex > 0) {
        // Swipe right - go to previous
        setState(() => _selectedArrival = _arrivalOptions[_arrivalIndex - 1]);
      } else if (velocity < 0 && _arrivalIndex < 1) {
        // Swipe left - go to next
        setState(() => _selectedArrival = _arrivalOptions[_arrivalIndex + 1]);
      }
    }
  }

  void _handleArrivalDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 2;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 1);

    if (newIndex != _arrivalIndex) {
      setState(() => _selectedArrival = _arrivalOptions[newIndex]);
    }
  }

  Widget _buildArrivalSegmentedButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / 2;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _handleArrivalDragUpdate(details, constraints.maxWidth),
            onHorizontalDragEnd: (details) =>
                _handleArrivalSwipe(details, constraints.maxWidth),
            child: Stack(
              children: [
                // Sliding indicator with bounce
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: _arrivalIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Items
                Row(
                  children: [
                    _buildArrivalItem(
                      'tiba',
                      'Tiba di sekolah',
                      Icons.check_circle_outline,
                    ),
                    _buildArrivalItem(
                      'akan_tiba',
                      'Akan tiba...',
                      Icons.schedule,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArrivalItem(String value, String label, IconData icon) {
    final isSelected = _selectedArrival == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedArrival = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.textMuted, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _estimatedTime != null
                ? AppColors.primary
                : AppColors.border,
            width: _estimatedTime != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _estimatedTime != null
                  ? _estimatedTime!.format(context)
                  : 'Pilih waktu estimasi',
              style: TextStyle(
                fontSize: 14,
                color: _estimatedTime != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: _estimatedTime != null
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SwipeToConfirm(
      text: 'Geser untuk panggil',
      onConfirm: _submitRequest,
    );
  }
}

// ============================================
// SWIPE TO CONFIRM WIDGET
// ============================================
class SwipeToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;

  const SwipeToConfirm({
    super.key,
    required this.text,
    required this.onConfirm,
  });

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  double _containerWidth = 0;
  bool _isConfirmed = false;
  late AnimationController _shimmerController;

  static const double _thumbSize = 52;
  static const double _padding = 4;

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
      // Konfirmasi berhasil
      setState(() {
        _dragPosition = _maxDragDistance;
        _isConfirmed = true;
      });

      // Haptic feedback dan panggil callback
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onConfirm();
      });
    } else {
      // Kembali ke posisi awal dengan animasi bounce
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

        // Kurva easeOutBack untuk efek bounce
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
            color: _isConfirmed ? Colors.green.shade500 : AppColors.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isConfirmed
                  ? Colors.green.shade500
                  : AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isConfirmed
                    ? Colors.green.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.15),
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
                        ? [Colors.green.shade500, Colors.green.shade400]
                        : [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primaryLight.withValues(alpha: 0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),

              // Text dengan shimmer effect
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
                            colors: [
                              AppColors.textMuted,
                              AppColors.primary,
                              AppColors.textMuted,
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
                      Icon(Icons.check_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sukses',
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
                        color: _isConfirmed ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isConfirmed
                                        ? Colors.green
                                        : AppColors.primary)
                                    .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isConfirmed
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                        color: _isConfirmed
                            ? Colors.green.shade500
                            : Colors.white,
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
