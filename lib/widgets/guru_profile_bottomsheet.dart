import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../main.dart';
import '../pages/login_page.dart';
import '../pages/guru/guru_profile_page.dart';

/// Bottom sheet untuk menampilkan profil guru dengan tombol logout
class GuruProfileBottomSheet extends StatelessWidget {
  final VoidCallback? onLogout;

  const GuruProfileBottomSheet({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          const SizedBox(height: 20),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Profil Saya',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profile Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GuruProfilePage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.shade400,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildAvatar(currentUser?.fotoUrl),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name and role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.nama ?? 'Guru',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
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
          ),
          const SizedBox(height: 16),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.border),
          ),

          // Logout button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _LogoutButton(
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? fotoUrl) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      final fullUrl = fotoUrl.startsWith('http')
          ? fotoUrl
          : 'https://soulhbc.com/penjemputan/$fotoUrl';

      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.amber.shade50,
            child: Icon(Icons.person, color: Colors.amber.shade700, size: 28),
          );
        },
      );
    }
    return Container(
      color: Colors.amber.shade50,
      child: Icon(Icons.person, color: Colors.amber.shade700, size: 28),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
  }

  void _performLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    if (context.mounted) {
      // Navigate to login page and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

/// Tombol logout
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            children: [
              // Logout icon
              Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keluar dari akun guru',
                      style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Color(0xFFDC2626), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Function helper untuk menampilkan GuruProfileBottomSheet
void showGuruProfileBottomSheet(
  BuildContext context, {
  VoidCallback? onLogout,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => GuruProfileBottomSheet(onLogout: onLogout),
  );
}
