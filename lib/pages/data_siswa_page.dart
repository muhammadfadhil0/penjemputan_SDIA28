import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../main.dart';
import '../services/auth/auth_service.dart';
import '../services/siswa/siswa_photo_service.dart';
import '../services/siswa/siswa_profile_service.dart';

// ============================================
// DATA SISWA PAGE (PROFILE SETTINGS)
// ============================================
class DataSiswaPage extends StatefulWidget {
  const DataSiswaPage({super.key});

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  final AuthService _authService = AuthService();
  final SiswaPhotoService _photoService = SiswaPhotoService();
  final SiswaProfileService _profileService = SiswaProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingPhoto = false;

  // Template avatar CDN untuk foto profil alternatif (DiceBear)
  static const List<Map<String, dynamic>> _avatarTemplates = [
    {'style': 'adventurer', 'label': 'Adventurer', 'color': Color(0xFF4FC3F7)},
    {
      'style': 'adventurer-neutral',
      'label': 'Neutral',
      'color': Color(0xFFFF8A80),
    },
    {'style': 'avataaars', 'label': 'Avataaars', 'color': Color(0xFFFFD54F)},
    {'style': 'big-smile', 'label': 'Big Smile', 'color': Color(0xFF81C784)},
    {'style': 'bottts', 'label': 'Robot', 'color': Color(0xFFCE93D8)},
    {'style': 'fun-emoji', 'label': 'Fun Emoji', 'color': Color(0xFF90CAF9)},
    {'style': 'lorelei', 'label': 'Lorelei', 'color': Color(0xFFFFE082)},
    {'style': 'notionists', 'label': 'Notionists', 'color': Color(0xFFA5D6A7)},
    {'style': 'thumbs', 'label': 'Thumbs', 'color': Color(0xFFFFD700)},
  ];

  // Generate DiceBear avatar URL
  String _getAvatarUrl(String style, String seed) {
    return 'https://api.dicebear.com/9.x/$style/png?seed=$seed&size=200&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
  }

  // Data siswa dari AuthService
  String get _namaLengkap => _authService.currentUser?.nama ?? 'Nama Lengkap';
  String get _namaPanggilan =>
      _authService.currentUser?.namaPanggilan ??
      _authService.currentUser?.nama.split(' ').first ??
      'Panggilan';
  String get _username => _authService.currentUser?.username ?? 'username';
  String get _namaKelas => _authService.currentUser?.namaKelas ?? 'Kelas';
  String? get _fotoUrl => _authService.currentUser?.fotoUrl;
  int get _siswaId => _authService.currentUser?.id ?? 0;

  void _showPhotoOptionsBottomSheet() {
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
            child: Material(
              color: Colors.transparent,
              child: _PhotoOptionsBottomSheet(
                onGalleryTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                onCameraTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                onAvatarTap: () {
                  Navigator.pop(context);
                  _showAvatarPickerBottomSheet();
                },
                onDeleteTap: _fotoUrl != null
                    ? () {
                        Navigator.pop(context);
                        _deletePhoto();
                      }
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAvatarPickerBottomSheet() {
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
            child: Material(
              color: Colors.transparent,
              child: _AvatarPickerBottomSheet(
                avatarTemplates: _avatarTemplates,
                seed: _namaLengkap,
                getAvatarUrl: _getAvatarUrl,
                onAvatarSelected: (avatarUrl) {
                  Navigator.pop(context);
                  _selectAvatar(avatarUrl);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        // Tambahkan delay kecil untuk menghindari konflik activity result
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _cropImage(pickedFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Foto',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            activeControlsWidgetColor: AppColors.primary,
          ),
          IOSUiSettings(
            title: 'Potong Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        await _uploadPhoto(File(croppedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memotong foto: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(File imageFile) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final result = await _photoService.uploadPhoto(_siswaId, imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.primary : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (result.success) {
          setState(() {});
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _deletePhoto() async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final result = await _photoService.deletePhoto(_siswaId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.primary : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (result.success) {
          setState(() {});
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _selectAvatar(String avatarUrl) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final result = await _photoService.updateAvatarUrl(_siswaId, avatarUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.primary : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (result.success) {
          setState(() {});
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  void _showEditProfileBottomSheet() {
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
            child: Material(
              color: Colors.transparent,
              child: _EditProfileBottomSheet(
                currentNama: _namaLengkap,
                currentNamaPanggilan:
                    _authService.currentUser?.namaPanggilan ?? '',
                onSave: (nama, namaPanggilan) async {
                  Navigator.pop(context);
                  await _updateProfile(nama, namaPanggilan, null);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordBottomSheet() {
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
            child: Material(
              color: Colors.transparent,
              child: _ChangePasswordBottomSheet(
                onSave: (newPassword) async {
                  Navigator.pop(context);
                  await _updateProfile(
                    _namaLengkap,
                    _authService.currentUser?.namaPanggilan,
                    newPassword,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProfile(
    String nama,
    String? namaPanggilan,
    String? password,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final result = await _profileService.updateProfile(
        siswaId: _siswaId,
        nama: nama,
        namaPanggilan: namaPanggilan,
        password: password,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.primary : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (result.success && result.updatedData != null) {
          // Update user data di AuthService
          await _authService.updateUserProfile(
            nama: result.updatedData!['nama'],
            namaPanggilan: result.updatedData!['nama_panggilan'],
          );
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 70),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Foto Profil (Rounded) dengan icon edit
            _buildProfilePhoto(),
            const SizedBox(height: 32),

            // Username (Read-only)
            _buildDataCard(
              icon: Icons.account_circle_outlined,
              label: 'Username',
              value: _username,
              isLocked: true,
            ),
            const SizedBox(height: 16),

            // Password
            _buildPasswordCard(),
            const SizedBox(height: 16),

            // Nama Lengkap
            _buildEditableDataCard(
              icon: Icons.person,
              label: 'Nama Lengkap',
              value: _namaLengkap,
              onEdit: _showEditProfileBottomSheet,
            ),
            const SizedBox(height: 16),

            // Nama Panggilan
            _buildEditableDataCard(
              icon: Icons.badge_outlined,
              label: 'Nama Panggilan',
              value: _namaPanggilan,
              onEdit: _showEditProfileBottomSheet,
            ),
            const SizedBox(height: 16),

            // Kelas (Read-only)
            _buildDataCard(
              icon: Icons.class_outlined,
              label: 'Kelas',
              value: _namaKelas,
              isLocked: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _isUploadingPhoto
                  ? Container(
                      color: AppColors.primaryLighter,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : _fotoUrl != null
                  ? Image.network(
                      _fotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.primaryLighter,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primaryLighter,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 70,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.primaryLighter,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 70,
                      ),
                    ),
            ),
          ),
          // Icon pensil untuk edit foto
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedScaleOnTap(
              onTap: _showPhotoOptionsBottomSheet,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String label,
    required String value,
    bool isLocked = false,
  }) {
    return ShadcnCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableDataCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return AnimatedScaleOnTap(
      onTap: onEdit,
      child: ShadcnCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return AnimatedScaleOnTap(
      onTap: _showChangePasswordBottomSheet,
      child: ShadcnCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '••••••••',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// EDIT PROFILE BOTTOM SHEET
// ============================================
class _EditProfileBottomSheet extends StatefulWidget {
  final String currentNama;
  final String currentNamaPanggilan;
  final Function(String nama, String namaPanggilan) onSave;

  const _EditProfileBottomSheet({
    required this.currentNama,
    required this.currentNamaPanggilan,
    required this.onSave,
  });

  @override
  State<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  late TextEditingController _namaController;
  late TextEditingController _namaPanggilanController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.currentNama);
    _namaPanggilanController = TextEditingController(
      text: widget.currentNamaPanggilan,
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _namaPanggilanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Edit Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Nama Lengkap Field
            _buildTextField(
              controller: _namaController,
              label: 'Nama Lengkap',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Nama Panggilan Field
            _buildTextField(
              controller: _namaPanggilanController,
              label: 'Nama Panggilan',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: AnimatedScaleOnTap(
                onTap: () {
                  if (_namaController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Nama lengkap harus diisi'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }
                  widget.onSave(
                    _namaController.text.trim(),
                    _namaPanggilanController.text.trim(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ============================================
// CHANGE PASSWORD BOTTOM SHEET
// ============================================
class _ChangePasswordBottomSheet extends StatefulWidget {
  final Function(String newPassword) onSave;

  const _ChangePasswordBottomSheet({required this.onSave});

  @override
  State<_ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState
    extends State<_ChangePasswordBottomSheet> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Ubah Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan password baru Anda',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // New Password Field
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Password Baru',
              obscure: _obscureNewPassword,
              onToggle: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Konfirmasi Password',
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: AnimatedScaleOnTap(
                onTap: () {
                  final newPassword = _newPasswordController.text.trim();
                  final confirmPassword = _confirmPasswordController.text
                      .trim();

                  if (newPassword.isEmpty) {
                    _showError('Password baru harus diisi');
                    return;
                  }
                  if (newPassword.length < 6) {
                    _showError('Password minimal 6 karakter');
                    return;
                  }
                  if (newPassword != confirmPassword) {
                    _showError('Konfirmasi password tidak cocok');
                    return;
                  }

                  widget.onSave(newPassword);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Simpan Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textMuted,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ============================================
// PHOTO OPTIONS BOTTOM SHEET
// ============================================
class _PhotoOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;
  final VoidCallback onAvatarTap;
  final VoidCallback? onDeleteTap;

  const _PhotoOptionsBottomSheet({
    required this.onGalleryTap,
    required this.onCameraTap,
    required this.onAvatarTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Ubah Foto Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: AppColors.primary,
                  onTap: onGalleryTap,
                ),
                _buildOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: Colors.orange,
                  onTap: onCameraTap,
                ),
                _buildOption(
                  icon: Icons.face_rounded,
                  label: 'Avatar',
                  color: Colors.purple,
                  onTap: onAvatarTap,
                ),
              ],
            ),

            if (onDeleteTap != null) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Delete option
              GestureDetector(
                onTap: onDeleteTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade600,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hapus Foto Profil',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// AVATAR PICKER BOTTOM SHEET
// ============================================
class _AvatarPickerBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> avatarTemplates;
  final String seed;
  final String Function(String style, String seed) getAvatarUrl;
  final Function(String avatarUrl) onAvatarSelected;

  const _AvatarPickerBottomSheet({
    required this.avatarTemplates,
    required this.seed,
    required this.getAvatarUrl,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.face_rounded,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pilih Avatar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Avatar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: avatarTemplates.length,
              itemBuilder: (context, index) {
                final avatar = avatarTemplates[index];
                final style = avatar['style'] as String;
                final label = avatar['label'] as String;
                final color = avatar['color'] as Color;
                final avatarUrl = getAvatarUrl(style, seed);

                return GestureDetector(
                  onTap: () => onAvatarSelected(avatarUrl),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: color,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
