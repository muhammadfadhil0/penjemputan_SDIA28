import 'package:flutter/material.dart';
import '../main.dart';

// ============================================
// GURU PENGUMUMAN FORM PAGE
// Form untuk membuat pengumuman baru
// ============================================
class GuruPengumumanFormPage extends StatefulWidget {
  final Function(PengumumanItem) onSave;

  const GuruPengumumanFormPage({super.key, required this.onSave});

  @override
  State<GuruPengumumanFormPage> createState() => _GuruPengumumanFormPageState();
}

class _GuruPengumumanFormPageState extends State<GuruPengumumanFormPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  String _selectedType = 'info';

  @override
  void dispose() {
    _judulController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Validate input
    if (_judulController.text.trim().isEmpty) {
      _showError('Judul tidak boleh kosong');
      return;
    }

    if (_keteranganController.text.trim().isEmpty) {
      _showError('Keterangan tidak boleh kosong');
      return;
    }

    // Create item and save
    final item = PengumumanItem(
      judul: _judulController.text.trim(),
      keterangan: _keteranganController.text.trim(),
      type: _selectedType,
      createdAt: DateTime.now(),
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
            Text('Pengumuman berhasil disimpan'),
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
      case 'warning':
        return 0;
      case 'info':
        return 1;
      default:
        return 1;
    }
  }

  final List<String> _typeOptions = ['warning', 'info'];

  void _handleTypeSwipe(DragEndDetails details, double containerWidth) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      if (velocity > 0 && _typeIndex > 0) {
        setState(() => _selectedType = _typeOptions[_typeIndex - 1]);
      } else if (velocity < 0 && _typeIndex < 1) {
        setState(() => _selectedType = _typeOptions[_typeIndex + 1]);
      }
    }
  }

  void _handleTypeDragUpdate(DragUpdateDetails details, double containerWidth) {
    final itemWidth = containerWidth / 2;
    final dragPosition = details.localPosition.dx;
    final newIndex = (dragPosition / itemWidth).floor().clamp(0, 1);

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
          'Pengumuman Baru',
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
              // Judul
              _buildLabel('Judul Pengumuman'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _judulController,
                hint: 'Masukkan judul pengumuman',
                icon: Icons.title_rounded,
              ),

              const SizedBox(height: 20),

              // Keterangan
              _buildLabel('Keterangan'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _keteranganController,
                hint: 'Masukkan keterangan pengumuman',
                icon: Icons.description_rounded,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Jenis pengumuman (icon slider)
              _buildLabel('Jenis Pengumuman'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
            child: Icon(icon, color: AppColors.textMuted, size: 22),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 48,
            minHeight: maxLines > 1 ? 100 : 48,
          ),
          alignLabelWithHint: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 14 : 14,
          ),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
          final itemWidth = (constraints.maxWidth) / 2;
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
                    _buildTypeItem(
                      'warning',
                      'Peringatan',
                      Icons.warning_rounded,
                    ),
                    _buildTypeItem('info', 'Informasi', Icons.info_rounded),
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
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'info':
        return AppColors.primary;
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

// Data model for Pengumuman items
class PengumumanItem {
  final String judul;
  final String keterangan;
  final String type; // warning, info
  final DateTime createdAt;

  PengumumanItem({
    required this.judul,
    required this.keterangan,
    required this.type,
    required this.createdAt,
  });
}
