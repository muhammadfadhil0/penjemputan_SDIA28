import 'package:flutter/material.dart';

// Import pages
import 'pages/jadwal_page.dart';
import 'pages/jemput_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/multi_account_service.dart';
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

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penjemputan',
      debugShowCheckedModeBanner: false,
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
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authService = AuthService();
    final multiAccountService = MultiAccountService();

    // Initialize multi-account service
    await multiAccountService.init();

    // Coba load session yang tersimpan
    final hasSession = await authService.loadStoredUser();

    if (!mounted) return;

    // Navigate berdasarkan status session
    if (hasSession) {
      // Sync first account to multi-account if not exists
      if (authService.currentUser != null &&
          !multiAccountService.isAccountRegistered(
            authService.currentUser!.id,
          )) {
        await multiAccountService.addAccount(authService.currentUser!);
      }

      // Ada session tersimpan, langsung ke halaman utama
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      // Tidak ada session, ke halaman login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
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
