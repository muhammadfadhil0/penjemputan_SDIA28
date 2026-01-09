import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/guru_multi_account_service.dart';
import '../services/auth/user_model.dart';
import '../main.dart';
import '../pages/login_merge_guru_and_class_page.dart';
import '../pages/guru/guru_profile_page.dart';
import 'account_switch_transition.dart';

/// Bottom sheet untuk menampilkan profil guru dan akun kelas yang terdaftar
/// Menggantikan implementasi sebelumnya dengan dukungan multi-account
class GuruProfileBottomSheet extends StatelessWidget {
  final VoidCallback? onAccountSwitched;

  const GuruProfileBottomSheet({super.key, this.onAccountSwitched});

  @override
  Widget build(BuildContext context) {
    final guruMultiAccountService = GuruMultiAccountService();
    final accounts = guruMultiAccountService.accounts;
    final activeAccountId = guruMultiAccountService.activeAccountId;
    final authService = AuthService();
    final currentUser = authService.currentUser;

    // Jika belum ada akun di service, tambahkan akun guru yang sedang aktif
    if (accounts.isEmpty && currentUser != null) {
      guruMultiAccountService.addAccount(currentUser);
    }

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
                  'Pusat Akun',
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

          // Account list - show accounts from GuruMultiAccountService or current user
          accounts.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isActive = account.id == activeAccountId;

                    return _AccountListItem(
                      account: account,
                      isActive: isActive,
                      onTap: () async {
                        if (!isActive) {
                          // Trigger page transition animation
                          AccountSwitchAnimationController().triggerAnimation();

                          await guruMultiAccountService.switchAccount(
                            account.id,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);

                            // Navigate to the appropriate page based on role
                            if (account.isKelas) {
                              // Navigate to KelasMainNavigation for kelas account
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const KelasMainNavigation(),
                                ),
                                (route) => false,
                              );
                            } else {
                              // Navigate to TeacherMainNavigation for guru account
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TeacherMainNavigation(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        } else {
                          // Navigate to profile page
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GuruProfilePage(),
                            ),
                          );
                        }
                      },
                    );
                  },
                )
              : _buildCurrentUserCard(context, currentUser),

          const SizedBox(height: 8),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.border),
          ),

          // Add kelas/guru account button (dynamic based on current user role)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Builder(
              builder: (context) {
                // If current user is kelas, show "Add Guru", otherwise show "Add Kelas"
                final isAddingGuru = currentUser?.isKelas ?? false;
                return _AddAccountButton(
                  isAddingGuru: isAddingGuru,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            LoginMergeGuruAndClassPage(
                              isAddingGuru: isAddingGuru,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard(BuildContext context, SiswaUser? currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GuruProfilePage()),
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
                  border: Border.all(color: Colors.amber.shade400, width: 2),
                ),
                child: ClipOval(
                  child: _buildAvatar(currentUser?.fotoUrl, true),
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
    );
  }

  Widget _buildAvatar(String? fotoUrl, bool isGuru) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      final fullUrl = fotoUrl.startsWith('http')
          ? fotoUrl
          : 'https://soulhbc.com/penjemputan/$fotoUrl';

      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: isGuru ? Colors.amber.shade50 : AppColors.primaryLighter,
            child: Icon(
              isGuru ? Icons.person : Icons.class_rounded,
              color: isGuru ? Colors.amber.shade700 : AppColors.primary,
              size: 28,
            ),
          );
        },
      );
    }
    return Container(
      color: isGuru ? Colors.amber.shade50 : AppColors.primaryLighter,
      child: Icon(
        isGuru ? Icons.person : Icons.class_rounded,
        color: isGuru ? Colors.amber.shade700 : AppColors.primary,
        size: 28,
      ),
    );
  }
}

/// Item untuk menampilkan satu akun dalam list
class _AccountListItem extends StatelessWidget {
  final SiswaUser account;
  final bool isActive;
  final VoidCallback onTap;

  const _AccountListItem({
    required this.account,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color scheme based on role
    final bool isGuru = account.isGuru;
    final Color accentColor = isGuru
        ? Colors.amber.shade400
        : AppColors.primary;
    final Color bgColor = isGuru
        ? Colors.amber.shade50
        : AppColors.primaryLighter;
    final String roleLabel = isGuru
        ? 'Guru Piket'
        : 'Kelas ${account.namaKelas ?? ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive ? bgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: isActive
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  )
                : null,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? accentColor : AppColors.border,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(child: _buildAvatar(isGuru)),
                ),
                const SizedBox(width: 14),

                // Name and role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.nama,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
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
                          color: isGuru
                              ? Colors.amber.shade100
                              : AppColors.primaryLighter,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: isGuru
                                ? Colors.amber.shade800
                                : AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active indicator
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isGuru) {
    if (account.fotoUrl != null && account.fotoUrl!.isNotEmpty) {
      final fullUrl = account.fotoUrl!.startsWith('http')
          ? account.fotoUrl!
          : 'https://soulhbc.com/penjemputan/${account.fotoUrl}';

      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: isGuru ? Colors.amber.shade50 : AppColors.primaryLighter,
            child: Icon(
              isGuru ? Icons.person : Icons.class_rounded,
              color: isGuru ? Colors.amber.shade700 : AppColors.primary,
              size: 24,
            ),
          );
        },
      );
    }
    return Container(
      color: isGuru ? Colors.amber.shade50 : AppColors.primaryLighter,
      child: Icon(
        isGuru ? Icons.person : Icons.class_rounded,
        color: isGuru ? Colors.amber.shade700 : AppColors.primary,
        size: 24,
      ),
    );
  }
}

/// Tombol untuk menambah akun guru/kelas baru
/// isAddingGuru: true jika menambah akun guru (saat login kelas), false jika menambah akun kelas
class _AddAccountButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isAddingGuru;

  const _AddAccountButton({required this.onTap, required this.isAddingGuru});

  @override
  Widget build(BuildContext context) {
    final title = isAddingGuru ? 'Tambah Akun Guru' : 'Tambah Akun Kelas';
    final subtitle = isAddingGuru
        ? 'Gabungkan akun guru ke profil ini'
        : 'Gabungkan akun kelas ke profil ini';
    final icon = isAddingGuru ? Icons.person_add : Icons.add;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Plus icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLighter,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
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
                Icons.chevron_right,
                color: AppColors.primary,
                size: 24,
              ),
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
  VoidCallback? onAccountSwitched,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) =>
        GuruProfileBottomSheet(onAccountSwitched: onAccountSwitched),
  );
}
