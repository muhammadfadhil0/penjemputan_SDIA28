import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Import pages
import 'pages/jadwal_page.dart';
import 'pages/jemput_page.dart';
import 'pages/guru_jemput_page.dart';
import 'pages/guru_riwayat_page.dart';
import 'pages/guru_antrean_page.dart';
import 'pages/guru_paket_page.dart';
import 'pages/kelas_ringkasan_page.dart';
import 'pages/kelas_riwayat_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/onboarding_page.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/multi_account_service.dart';
import 'services/auth/guru_multi_account_service.dart';
import 'services/notifications/notification_service.dart';
import 'widgets/account_switch_transition.dart';

// Export pages for use in other files
export 'pages/jadwal_page.dart';
export 'pages/jemput_page.dart';
export 'pages/profile_page.dart';
export 'pages/data_siswa_page.dart';
export 'pages/riwayat_penjemputan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service with error handling
  // This prevents the app from getting stuck on splash in release mode
  try {
    await NotificationService().initialize();
  } catch (e) {
    // Log error but continue app execution
    debugPrint('NotificationService init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penjemputan',
      debugShowCheckedModeBanner: false,
      // navigatorObservers: [observer],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

// ============================================
// SPLASH PAGE - Session Check
// ============================================
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const String _initialOnboardingKey =
      'has_completed_initial_onboarding';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // FIRST: Check if initial onboarding was completed
      final hasCompletedOnboarding =
          prefs.getBool(_initialOnboardingKey) ?? false;

      if (!hasCompletedOnboarding) {
        // First install - show onboarding BEFORE login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
          );
        }
        return;
      }

      // Onboarding completed, proceed with session check
      final authService = AuthService();
      final multiAccountService = MultiAccountService();
      final guruMultiAccountService = GuruMultiAccountService();

      // Initialize multi-account services with timeout
      await multiAccountService.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('MultiAccountService init timeout');
        },
      );

      // Initialize guru multi-account service
      await guruMultiAccountService.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('GuruMultiAccountService init timeout');
        },
      );

      // Coba load session yang tersimpan
      final hasSession = await authService.loadStoredUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!mounted) return;

      // Navigate berdasarkan status session
      if (hasSession) {
        final user = authService.currentUser;

        // Sync account to appropriate multi-account service
        if (user != null) {
          if (user.isGuru || user.isKelas) {
            // Guru/Kelas: sync to GuruMultiAccountService
            if (!guruMultiAccountService.isAccountRegistered(user.id)) {
              await guruMultiAccountService.addAccount(user);
            }
          } else {
            // Siswa: sync to MultiAccountService
            if (!multiAccountService.isAccountRegistered(user.id)) {
              await multiAccountService.addAccount(user);
            }
          }
        }

        // Cek role untuk menentukan halaman tujuan
        if (user != null && user.role == 'guru') {
          // Guru: navigate ke TeacherMainNavigation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const TeacherMainNavigation(),
            ),
          );
        } else if (user != null && user.isKelas) {
          // Kelas: navigate ke KelasMainNavigation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const KelasMainNavigation(),
            ),
          );
        } else {
          // Siswa/Ortu: navigate ke MainNavigation biasa
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } else {
        // Tidak ada session, ke halaman login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      // If anything fails, navigate to login page
      debugPrint('Session check failed: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('lib/assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shadcn-style Colors
class AppColors {
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryLighter = Color(0xFFDBEAFE);
  static const Color background = Color(0xFFFAFAFA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
}

// ============================================
// TEACHER MAIN NAVIGATION
// For guru/teacher role - 4 tabs: Paket, Riwayat, Panggil, Antrean
// ============================================
class TeacherMainNavigation extends StatefulWidget {
  const TeacherMainNavigation({super.key});

  @override
  State<TeacherMainNavigation> createState() => _TeacherMainNavigationState();
}

class _TeacherMainNavigationState extends State<TeacherMainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2; // Start at Panggil (center)
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  double _indicatorPosition = 2.0;

  final List<Widget> _pages = const [
    GuruPaketPage(),
    GuruRiwayatPage(),
    GuruPickupDashboardPage(),
    GuruAntreanPage(),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 2.0, end: 2.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _animateToIndex(int newIndex) {
    _indicatorAnimation =
        Tween<double>(
          begin: _indicatorPosition,
          end: newIndex.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _indicatorController,
            curve: Curves.easeOutBack,
          ),
        );

    _indicatorController.forward(from: 0).then((_) {
      _indicatorPosition = newIndex.toDouble();
    });

    setState(() => _currentIndex = newIndex);
  }

  // Handle swipe gestures on the nav bar
  void _handleNavBarSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      if (velocity > 0 && _currentIndex > 0) {
        _animateToIndex(_currentIndex - 1);
      } else if (velocity < 0 && _currentIndex < 3) {
        _animateToIndex(_currentIndex + 1);
      }
    }
  }

  // Handle drag update for direct selection
  void _handleNavBarDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 4;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 3);

    if (newIndex != _currentIndex) {
      _animateToIndex(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AccountSwitchAnimatedPage(child: _pages[_currentIndex]),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 4;
              return GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    _handleNavBarDragUpdate(details, constraints.maxWidth),
                onHorizontalDragEnd: _handleNavBarSwipe,
                child: Stack(
                  children: [
                    // Animated indicator with bounce effect
                    AnimatedBuilder(
                      animation: _indicatorAnimation,
                      builder: (context, child) {
                        final position = _indicatorAnimation.value;
                        final isCenter = position.round() == 2;
                        return Positioned(
                          left:
                              position * itemWidth +
                              (itemWidth - (isCenter ? 90 : 70)) / 2,
                          top: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isCenter ? 90 : 70,
                            decoration: BoxDecoration(
                              color: isCenter
                                  ? AppColors.primary
                                  : AppColors.primaryLighter,
                              borderRadius: BorderRadius.circular(
                                isCenter ? 20 : 12,
                              ),
                              boxShadow: isCenter
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    // Nav items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2,
                          label: 'Paket',
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.history_outlined,
                          activeIcon: Icons.history,
                          label: 'Riwayat',
                        ),
                        _buildNavItem(
                          index: 2,
                          icon: Icons.campaign_outlined,
                          activeIcon: Icons.campaign,
                          label: 'Panggil',
                          isCenter: true,
                        ),
                        _buildNavItem(
                          index: 3,
                          icon: Icons.queue_outlined,
                          activeIcon: Icons.queue,
                          label: 'Antrean',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isCenter = false,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            _animateToIndex(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? (isCenter ? Colors.white : AppColors.primary)
                    : AppColors.textMuted,
                size: isCenter ? 26 : 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isCenter ? Colors.white : AppColors.primary)
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Navigation with Bottom Nav Bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  double _indicatorPosition = 1.0; // Start at center (index 1)

  final List<Widget> _pages = const [
    JadwalPage(),
    PickupDashboardPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400), // Longer duration for bounce
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorController,
        curve: Curves.easeOutBack,
      ), // Bouncy curve
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _animateToIndex(int newIndex) {
    _indicatorAnimation =
        Tween<double>(
          begin: _indicatorPosition,
          end: newIndex.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _indicatorController,
            curve: Curves.easeOutBack, // Bouncy curve
          ),
        );

    _indicatorController.forward(from: 0).then((_) {
      _indicatorPosition = newIndex.toDouble();
    });

    setState(() => _currentIndex = newIndex);
  }

  // Handle swipe gestures on the nav bar
  void _handleNavBarSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      // Swipe detected
      if (velocity > 0 && _currentIndex > 0) {
        // Swipe right - go to previous tab
        _animateToIndex(_currentIndex - 1);
      } else if (velocity < 0 && _currentIndex < 2) {
        // Swipe left - go to next tab
        _animateToIndex(_currentIndex + 1);
      }
    }
  }

  // Handle drag update for direct selection
  void _handleNavBarDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 3;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 2);

    if (newIndex != _currentIndex) {
      _animateToIndex(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with bottom navigation
        Scaffold(
          body: AccountSwitchAnimatedPage(child: _pages[_currentIndex]),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 3;
              return GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    _handleNavBarDragUpdate(details, constraints.maxWidth),
                onHorizontalDragEnd: _handleNavBarSwipe,
                child: Stack(
                  children: [
                    // Animated indicator with bounce effect
                    AnimatedBuilder(
                      animation: _indicatorAnimation,
                      builder: (context, child) {
                        final position = _indicatorAnimation.value;
                        final isCenter = position.round() == 1;
                        return Positioned(
                          left:
                              position * itemWidth +
                              (itemWidth - (isCenter ? 90 : 70)) / 2,
                          top: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isCenter ? 90 : 70,
                            decoration: BoxDecoration(
                              color: isCenter
                                  ? AppColors.primary
                                  : AppColors.primaryLighter,
                              borderRadius: BorderRadius.circular(
                                isCenter ? 20 : 12,
                              ),
                              boxShadow: isCenter
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    // Nav items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.calendar_today_outlined,
                          activeIcon: Icons.calendar_today,
                          label: 'Jadwal',
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.directions_car_outlined,
                          activeIcon: Icons.directions_car,
                          label: 'Jemput',
                          isCenter: true,
                        ),
                        _buildNavItem(
                          index: 2,
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isCenter = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          _animateToIndex(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCenter ? 24 : 16,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? (isCenter ? Colors.white : AppColors.primary)
                  : AppColors.textMuted,
              size: isCenter ? 26 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isCenter ? Colors.white : AppColors.primary)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Scale Widget (untuk button jemput dan bottom sheet)
class AnimatedScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;

  const AnimatedScaleOnTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.95,
  });

  @override
  State<AnimatedScaleOnTap> createState() => _AnimatedScaleOnTapState();
}

class _AnimatedScaleOnTapState extends State<AnimatedScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

// Shadcn Card Widget
class ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ShadcnCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

// ============================================
// KELAS MAIN NAVIGATION
// For kelas/class_viewer role - 2 tabs: Ringkasan, Riwayat
// ============================================
class KelasMainNavigation extends StatefulWidget {
  const KelasMainNavigation({super.key});

  @override
  State<KelasMainNavigation> createState() => _KelasMainNavigationState();
}

class _KelasMainNavigationState extends State<KelasMainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // Start at Ringkasan
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  double _indicatorPosition = 0.0;

  final AuthService _authService = AuthService();

  final List<Widget> _pages = const [KelasRingkasanPage(), KelasRiwayatPage()];

  /// Logout dan navigasi ke login page
  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Keluar dari Akun?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Logout dan bersihkan semua data lokal
      await _authService.logout();

      // Navigasi ke login page dan hapus semua route sebelumnya
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _animateToIndex(int newIndex) {
    _indicatorAnimation =
        Tween<double>(
          begin: _indicatorPosition,
          end: newIndex.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _indicatorController,
            curve: Curves.easeOutBack,
          ),
        );

    _indicatorController.forward(from: 0).then((_) {
      _indicatorPosition = newIndex.toDouble();
    });

    setState(() => _currentIndex = newIndex);
  }

  // Handle swipe gestures on the nav bar
  void _handleNavBarSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      if (velocity > 0 && _currentIndex > 0) {
        _animateToIndex(_currentIndex - 1);
      } else if (velocity < 0 && _currentIndex < 1) {
        _animateToIndex(_currentIndex + 1);
      }
    }
  }

  // Handle drag update for direct selection
  void _handleNavBarDragUpdate(
    DragUpdateDetails details,
    double containerWidth,
  ) {
    final itemWidth = containerWidth / 2;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 1);

    if (newIndex != _currentIndex) {
      _animateToIndex(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'Ringkasan',
                isFirst: _currentIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'Riwayat',
                isFirst: _currentIndex == 1,
              ),
              // Logout button styled same as nav items
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isFirst = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          _animateToIndex(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol logout di kanan navbar
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade500, size: 24),
            const SizedBox(height: 4),
            Text(
              'Keluar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
