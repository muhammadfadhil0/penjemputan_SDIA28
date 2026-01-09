import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/guru_multi_account_service.dart';

// ============================================
// LOGIN MERGE GURU AND CLASS PAGE
// Supports adding both guru (when logged in as kelas) and kelas (when logged in as guru) accounts
// ============================================
class LoginMergeGuruAndClassPage extends StatefulWidget {
  // If true, adding guru account. If false, adding kelas account.
  final bool isAddingGuru;

  const LoginMergeGuruAndClassPage({super.key, this.isAddingGuru = false});

  @override
  State<LoginMergeGuruAndClassPage> createState() =>
      _LoginMergeGuruAndClassPageState();
}

class _LoginMergeGuruAndClassPageState
    extends State<LoginMergeGuruAndClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleMerge() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Capture context before async operation
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        // Call login API
        final authService = AuthService();
        final result = await authService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        if (result.success && result.user != null) {
          // Validate role based on what we're adding
          if (widget.isAddingGuru) {
            // Adding guru - validate it's a guru account
            if (!result.user!.isGuru) {
              setState(() => _isLoading = false);
              messenger.showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ini bukan akun guru. Silakan gunakan akun guru.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return;
            }
          } else {
            // Adding kelas - validate it's a kelas account
            if (!result.user!.isKelas) {
              setState(() => _isLoading = false);
              messenger.showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ini bukan akun kelas. Silakan gunakan akun kelas.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return;
            }
          }

          // Check if account already exists
          final guruMultiAccountService = GuruMultiAccountService();
          if (guruMultiAccountService.isAccountRegistered(result.user!.id)) {
            setState(() => _isLoading = false);
            final accountType = widget.isAddingGuru ? 'guru' : 'kelas';
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Akun $accountType ini sudah terdaftar'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            return;
          }

          // Add account to GuruMultiAccountService
          await guruMultiAccountService.addAccount(result.user!);

          setState(() => _isLoading = false);

          // Show success message
          final successName = widget.isAddingGuru
              ? result.user!.nama
              : (result.user!.namaKelas ?? result.user!.displayName);
          final accountLabel = widget.isAddingGuru ? 'Guru' : 'Kelas';

          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$accountLabel $successName berhasil ditambahkan!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          navigator.pop();
        } else {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Terjadi kesalahan. Silakan coba lagi.')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic text based on whether adding guru or kelas
    final pageTitle = widget.isAddingGuru
        ? 'Tambah Akun Guru'
        : 'Tambah Akun Kelas';
    final usernameLabel = widget.isAddingGuru
        ? 'Username Guru'
        : 'Username Kelas';
    final usernameHint = widget.isAddingGuru
        ? 'Masukkan username guru'
        : 'Masukkan username kelas';
    final infoText = widget.isAddingGuru
        ? 'Masukkan data login guru yang ingin ditambahkan ke profil Anda'
        : 'Masukkan data login kelas yang ingin ditambahkan ke profil Anda';
    final iconData = widget.isAddingGuru ? Icons.person : Icons.class_rounded;
    final buttonText = widget.isAddingGuru
        ? 'Tambah Akun Guru'
        : 'Tambah Akun Kelas';
    final buttonIcon = widget.isAddingGuru ? Icons.person_add : Icons.link;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(iconData, size: 60, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Info text
              Center(
                child: Text(
                  infoText,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Username Field
              _buildLabel(usernameLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.name,
                decoration: _inputDecoration(
                  hint: usernameHint,
                  prefixIcon: widget.isAddingGuru
                      ? Icons.person_outline
                      : Icons.class_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              _buildLabel('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration(
                  hint: 'Masukkan password',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleMerge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(buttonIcon, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Help text
              Center(
                child: Text(
                  'Hubungi admin sekolah jika Anda lupa password',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(prefixIcon, color: AppColors.textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
