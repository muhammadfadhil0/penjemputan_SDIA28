import 'package:flutter/material.dart';
import '../services/auth/user_model.dart';
import '../services/auth/multi_account_service.dart';
import '../main.dart';
import '../pages/login_merge_murid_page.dart';
import 'account_switch_transition.dart';

/// Bottom sheet untuk menampilkan list akun dan switch antar akun
/// Mirip dengan fitur switch akun di Instagram
class AccountSwitcherBottomSheet extends StatelessWidget {
  final VoidCallback? onAccountSwitched;

  const AccountSwitcherBottomSheet({super.key, this.onAccountSwitched});

  @override
  Widget build(BuildContext context) {
    final multiAccountService = MultiAccountService();
    final accounts = multiAccountService.accounts;
    final activeAccountId = multiAccountService.activeAccountId;

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
                  Icons.people_outline_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Pilih Akun',
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

          // Account list
          ListView.builder(
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

                    await multiAccountService.switchAccount(account.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      onAccountSwitched?.call();
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),

          const SizedBox(height: 8),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.border),
          ),

          // Add account button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _AddAccountButton(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginMergeMuridPage(),
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
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive ? AppColors.primaryLighter : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(child: _buildAvatar()),
                ),
                const SizedBox(width: 14),

                // Name and class
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelas ${account.namaKelas}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active indicator
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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

  Widget _buildAvatar() {
    if (account.fotoUrl != null && account.fotoUrl!.isNotEmpty) {
      return Image.network(
        account.fotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primaryLighter,
            child: Icon(Icons.person, color: AppColors.primary, size: 24),
          );
        },
      );
    }
    return Container(
      color: AppColors.primaryLighter,
      child: const Icon(Icons.person, color: AppColors.primary, size: 24),
    );
  }
}

/// Tombol untuk menambah akun baru
class _AddAccountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Text
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Akun Murid',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Login dengan akun siswa lain',
                      style: TextStyle(
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

/// Function helper untuk menampilkan AccountSwitcherBottomSheet
void showAccountSwitcher(
  BuildContext context, {
  VoidCallback? onAccountSwitched,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) =>
        AccountSwitcherBottomSheet(onAccountSwitched: onAccountSwitched),
  );
}
