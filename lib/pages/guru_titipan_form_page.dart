import 'package:flutter/material.dart';
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
