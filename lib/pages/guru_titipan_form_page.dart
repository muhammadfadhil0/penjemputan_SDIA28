import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import 'guru_paket_page.dart';

// ============================================
// GURU TITIPAN FORM PAGE
// Form untuk membuat titipan baru
// ============================================
class GuruTitipanFormPage extends StatefulWidget {
  final Function(PaketItem) onSave;

  const GuruTitipanFormPage({super.key, required this.onSave});

  @override
  State<GuruTitipanFormPage> createState() => _GuruTitipanFormPageState();
}

class _GuruTitipanFormPageState extends State<GuruTitipanFormPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _barangController = TextEditingController();

  String _selectedType = 'food';
  bool _isGuru = false;

  // Image picker
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Daftar kelas dummy untuk demo
  final List<String> _kelasList = [
    'Kelas 1A',
    'Kelas 1B',
    'Kelas 2A',
    'Kelas 2B',
    'Kelas 3A',
    'Kelas 3B',
    'Kelas 4A',
    'Kelas 4B',
    'Kelas 5A',
    'Kelas 5B',
    'Kelas 6A',
    'Kelas 6B',
  ];

  String? _selectedKelas;

  @override
  void dispose() {
    _namaController.dispose();
    _kelasController.dispose();
    _barangController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Validate input
    if (_namaController.text.trim().isEmpty) {
      _showError('Nama penerima tidak boleh kosong');
      return;
    }

    if (!_isGuru && _selectedKelas == null) {
      _showError('Pilih kelas untuk siswa');
      return;
    }

    if (_barangController.text.trim().isEmpty) {
      _showError('Nama barang tidak boleh kosong');
      return;
    }

    // Create item and save
    final item = PaketItem(
      namaPenerima: _namaController.text.trim(),
      kelas: _isGuru ? null : _selectedKelas,
      namaBarang: _barangController.text.trim(),
      type: _selectedType,
      createdAt: DateTime.now(),
      isGuru: _isGuru,
      imagePath: _selectedImage?.path,
    );

    widget.onSave(item);

    // Go back
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Titipan berhasil disimpan'),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ===== IMAGE PICKER METHODS =====
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(context);
                        _getImageFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(context);
                        _getImageFromGallery();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImageFromCamera() async {
    bool shouldRetake = true;

    while (shouldRetake && mounted) {
      try {
        // Use image_picker to capture photo
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );

        if (image != null) {
          final file = File(image.path);

          // Verify file exists and has content
          if (await file.exists() && await file.length() > 0) {
            // Show review bottom sheet
            if (mounted) {
              final bool? confirmed = await _showPhotoReviewBottomSheet(file);
              if (confirmed == true && mounted) {
                setState(() {
                  _selectedImage = file;
                });
                shouldRetake = false; // Exit loop - photo saved
              } else if (confirmed == false) {
                // User clicked "Ulang" - continue loop to open camera again
                shouldRetake = true;
              } else {
                // User dismissed bottom sheet (null) - exit loop
                shouldRetake = false;
              }
            }
          } else {
            _showError('Gagal mengambil foto');
            shouldRetake = false;
          }
        } else {
          // User cancelled camera - exit loop
          shouldRetake = false;
        }
      } catch (e) {
        _showError('Gagal mengakses kamera');
        shouldRetake = false;
      }
    }
  }

  Future<bool?> _showPhotoReviewBottomSheet(File imageFile) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoReviewBottomSheet(imageFile: imageFile),
    );
  }

  Future<void> _getImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        // Verify file exists and has content
        final file = File(image.path);
        if (await file.exists() && await file.length() > 0) {
          setState(() {
            _selectedImage = file;
          });
        } else {
          _showError('File gambar tidak valid');
        }
      }
    } catch (e) {
      _showError('Gagal mengakses galeri');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  int get _typeIndex {
    switch (_selectedType) {
      case 'food':
        return 0;
      case 'pakaian':
        return 1;
      case 'surat':
        return 2;
      case 'drink':
        return 3;
      default:
        return 0;
    }
  }

  final List<String> _typeOptions = ['food', 'pakaian', 'surat', 'drink'];

  void _handleTypeSwipe(DragEndDetails details, double containerWidth) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      if (velocity > 0 && _typeIndex > 0) {
        setState(() => _selectedType = _typeOptions[_typeIndex - 1]);
      } else if (velocity < 0 && _typeIndex < 3) {
        setState(() => _selectedType = _typeOptions[_typeIndex + 1]);
      }
    }
  }

  void _handleTypeDragUpdate(DragUpdateDetails details, double containerWidth) {
    final itemWidth = containerWidth / 4;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 3);

    if (newIndex != _typeIndex) {
      setState(() => _selectedType = _typeOptions[newIndex]);
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'Titipan Baru',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle: Siswa atau Guru
              _buildLabel('Penerima adalah:'),
              const SizedBox(height: 10),
              _buildRecipientToggle(),

              const SizedBox(height: 20),

              // Nama penerima
              _buildLabel(_isGuru ? 'Nama Guru' : 'Nama Siswa'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _namaController,
                hint: _isGuru ? 'Masukkan nama guru' : 'Masukkan nama siswa',
                icon: Icons.person_outline_rounded,
              ),

              // Kelas (hanya untuk siswa)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _isGuru
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildLabel('Kelas'),
                          const SizedBox(height: 10),
                          _buildKelasDropdown(),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // Nama barang
              _buildLabel('Nama Barang'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _barangController,
                hint: 'Masukkan nama barang',
                icon: Icons.inventory_2_outlined,
              ),

              const SizedBox(height: 20),

              // Foto barang
              _buildLabel('Foto Barang (Opsional)'),
              const SizedBox(height: 10),
              _buildImagePicker(),

              const SizedBox(height: 24),

              // Jenis barang (icon slider)
              _buildLabel('Jenis Barang'),
              const SizedBox(height: 10),
              _buildTypeSelector(),

              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
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
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRecipientToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isGuru = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isGuru ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isGuru
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: !_isGuru ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Siswa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !_isGuru
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isGuru = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isGuru ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isGuru
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: _isGuru ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Guru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isGuru ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildKelasDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedKelas,
        hint: Text(
          'Pilih kelas',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.class_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        items: _kelasList.map((kelas) {
          return DropdownMenuItem<String>(
            value: kelas,
            child: Text(
              kelas,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedKelas = value;
          });
        },
        dropdownColor: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImage != null
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: _selectedImage != null
            ? _buildSelectedImage()
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 28,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ketuk untuk menambahkan foto',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Kamera atau Galeri',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSelectedImage() {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Foto berhasil ditambahkan',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / 4;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _handleTypeDragUpdate(details, constraints.maxWidth),
            onHorizontalDragEnd: (details) =>
                _handleTypeSwipe(details, constraints.maxWidth),
            child: Stack(
              children: [
                // Sliding indicator with bounce
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: _typeIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getTypeColor(_selectedType),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor(_selectedType).withOpacity(0.3),
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
                    _buildTypeItem('food', 'Makanan', Icons.fastfood_rounded),
                    _buildTypeItem(
                      'pakaian',
                      'Pakaian',
                      Icons.checkroom_rounded,
                    ),
                    _buildTypeItem('surat', 'Surat', Icons.mail_rounded),
                    _buildTypeItem(
                      'drink',
                      'Minuman',
                      Icons.local_drink_rounded,
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'food':
        return const Color(0xFFF59E0B);
      case 'pakaian':
        return const Color(0xFF8B5CF6);
      case 'surat':
        return const Color(0xFF3B82F6);
      case 'drink':
        return const Color(0xFF10B981);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildTypeItem(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// PHOTO REVIEW BOTTOM SHEET
// Review captured photo with save/retake options
// ============================================
class _PhotoReviewBottomSheet extends StatelessWidget {
  final File imageFile;

  const _PhotoReviewBottomSheet({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Hasil Foto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Image preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gagal memuat foto',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Retake button
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ulang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Confirm button
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
