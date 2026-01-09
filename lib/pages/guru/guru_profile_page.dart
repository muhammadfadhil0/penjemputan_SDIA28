import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth/auth_service.dart';
import '../login_page.dart';
import 'guru_data_page.dart';

class GuruProfilePage extends StatefulWidget {
  const GuruProfilePage({super.key});

  @override
  State<GuruProfilePage> createState() => _GuruProfilePageState();
}

class _GuruProfilePageState extends State<GuruProfilePage> {
  final AuthService _authService = AuthService();

  // Check if current user is kelas
  bool get _isKelas => _authService.currentUser?.isKelas ?? false;

  // Dynamic name based on role
  String get _displayName => _isKelas
      ? (_authService.currentUser?.namaKelas ??
            _authService.currentUser?.nama ??
            'Kelas')
      : (_authService.currentUser?.nama ?? 'Guru');
  String? get _fotoUrl => _authService.currentUser?.fotoUrl;

  // Dynamic labels based on role
  String get _pageTitle => _isKelas ? 'Profil Kelas' : 'Profil Saya';
  String get _roleLabel => _isKelas ? 'Akun Kelas' : 'Guru Piket';
  String get _dataMenuTitle => _isKelas ? 'Data Kelas' : 'Data Guru';
  String get _dataMenuSubtitle =>
      _isKelas ? 'Lihat dan ubah data kelas' : 'Ubah foto profil dan data diri';
  String get _logoutSubtitle =>
      _isKelas ? 'Keluar dari akun kelas' : 'Keluar dari akun guru';
  IconData get _avatarIcon =>
      _isKelas ? Icons.class_rounded : Icons.person_rounded;
  Color get _accentColor =>
      _isKelas ? AppColors.primary : Colors.amber.shade400;
  Color get _accentColorLight =>
      _isKelas ? AppColors.primaryLighter : Colors.amber.shade50;
  Color get _accentColorDark =>
      _isKelas ? AppColors.primary : Colors.amber.shade700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _pageTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor, width: 3),
                    ),
                    child: ClipOval(
                      child: _fotoUrl != null && !_isKelas
                          ? Builder(
                              builder: (context) {
                                final fullUrl = _fotoUrl!.startsWith('http')
                                    ? _fotoUrl!
                                    : 'https://soulhbc.com/penjemputan/$_fotoUrl';

                                return Image.network(
                                  fullUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: _accentColorLight,
                                        child: Icon(
                                          _avatarIcon,
                                          color: _accentColorDark,
                                          size: 60,
                                        ),
                                      ),
                                );
                              },
                            )
                          : Container(
                              color: _accentColorLight,
                              child: Icon(
                                _avatarIcon,
                                color: _accentColorDark,
                                size: 60,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColorLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _roleLabel,
                      style: TextStyle(
                        color: _isKelas
                            ? AppColors.primary
                            : Colors.amber.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Menu Items
            _buildMenuItem(
              icon: _isKelas
                  ? Icons.class_outlined
                  : Icons.person_outline_rounded,
              title: _dataMenuTitle,
              subtitle: _dataMenuSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuruDataPage()),
                ).then((_) => setState(() {})); // Refresh when back
              },
            ),

            // Logout Menu
            const SizedBox(height: 7),
            _buildLogoutMenuItem(onTap: _showLogoutConfirmation),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutMenuItem({required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _logoutSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.red.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
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
              _performLogout();
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

  void _performLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
