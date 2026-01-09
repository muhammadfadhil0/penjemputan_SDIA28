import 'package:flutter/material.dart';
import '../main.dart';
import 'guru_titipan_form_page.dart';
import 'guru_pengumuman_form_page.dart';

// ============================================
// GURU PAKET PAGE
// Halaman untuk mengelola titipan dan pengumuman
// ============================================
class GuruPaketPage extends StatefulWidget {
  const GuruPaketPage({super.key});

  @override
  State<GuruPaketPage> createState() => _GuruPaketPageState();
}

class _GuruPaketPageState extends State<GuruPaketPage>
    with SingleTickerProviderStateMixin {
  // FAB expansion state
  bool _isFabExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabRotationAnimation;
  late Animation<double> _fabScaleAnimation;

  // Sample data for packages (UI only, no backend)
  final List<PaketItem> _paketItems = [];
  final List<PengumumanItem> _pengumumanItems = [];

  // Track expanded card index (-1000 offset for pengumuman)
  int? _expandedCardIndex;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabRotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fabScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabExpanded) {
      setState(() {
        _isFabExpanded = false;
        _fabAnimationController.reverse();
      });
    }
  }

  void _onTitipanTap() {
    _closeFab();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuruTitipanFormPage(
          onSave: (item) {
            setState(() {
              _paketItems.insert(0, item);
            });
          },
        ),
      ),
    );
  }

  void _onPengumumanTap() {
    _closeFab();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuruPengumumanFormPage(
          onSave: (item) {
            setState(() {
              _pengumumanItems.insert(0, item);
            });
          },
        ),
      ),
    );
  }

  void _toggleCardExpansion(int index) {
    setState(() {
      if (_expandedCardIndex == index) {
        _expandedCardIndex = null;
      } else {
        _expandedCardIndex = index;
      }
    });
  }

  void _markAsPickedUp(int index) {
    setState(() {
      _paketItems.removeAt(index);
      _expandedCardIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Barang telah diambil'),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'food':
        return Icons.fastfood_rounded;
      case 'pakaian':
        return Icons.checkroom_rounded;
      case 'surat':
        return Icons.mail_rounded;
      case 'drink':
        return Icons.local_drink_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getColorForType(String type) {
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

  String _getLabelForType(String type) {
    switch (type) {
      case 'food':
        return 'Makanan';
      case 'pakaian':
        return 'Pakaian';
      case 'surat':
        return 'Surat';
      case 'drink':
        return 'Minuman';
      default:
        return 'Lainnya';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeFab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paket',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Kelola titipan & pengumuman',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: (_paketItems.isEmpty && _pengumumanItems.isEmpty)
                    ? _buildEmptyState()
                    : _buildCombinedList(),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildExpandableFab(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada paket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambah titipan\natau pengumuman baru',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildCombinedList() {
    // Combine items with type info for sorting
    final List<dynamic> allItems = [];

    for (int i = 0; i < _pengumumanItems.length; i++) {
      allItems.add({
        'type': 'pengumuman',
        'index': i,
        'item': _pengumumanItems[i],
      });
    }

    for (int i = 0; i < _paketItems.length; i++) {
      allItems.add({'type': 'titipan', 'index': i, 'item': _paketItems[i]});
    }

    // Sort by creation time (newest first)
    allItems.sort((a, b) {
      final aTime = a['type'] == 'pengumuman'
          ? (a['item'] as PengumumanItem).createdAt
          : (a['item'] as PaketItem).createdAt;
      final bTime = b['type'] == 'pengumuman'
          ? (b['item'] as PengumumanItem).createdAt
          : (b['item'] as PaketItem).createdAt;
      return bTime.compareTo(aTime);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final itemData = allItems[index];
        if (itemData['type'] == 'pengumuman') {
          return _buildPengumumanCard(
            itemData['item'] as PengumumanItem,
            itemData['index'] as int,
          );
        } else {
          return _buildTitipanCard(
            itemData['item'] as PaketItem,
            itemData['index'] as int,
          );
        }
      },
    );
  }

  Widget _buildPengumumanCard(PengumumanItem item, int originalIndex) {
    // Use negative index offset for pengumuman to differentiate from titipan
    final cardIndex = -1000 - originalIndex;
    final isExpanded = _expandedCardIndex == cardIndex;
    final iconColor = item.type == 'warning'
        ? const Color(0xFFF59E0B)
        : AppColors.primary;
    final icon = item.type == 'warning'
        ? Icons.warning_rounded
        : Icons.info_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleCardExpansion(cardIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? iconColor.withOpacity(0.3) : AppColors.border,
              width: isExpanded ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? iconColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isExpanded ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PENGUMUMAN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: iconColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.judul,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(item.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand indicator
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Keterangan
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.keterangan,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Delete button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _removePengumuman(originalIndex),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus Pengumuman',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePengumuman(int index) {
    setState(() {
      _pengumumanItems.removeAt(index);
      _expandedCardIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Pengumuman telah dihapus'),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTitipanCard(PaketItem item, int index) {
    final isExpanded = _expandedCardIndex == index;
    final iconColor = _getColorForType(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleCardExpansion(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? iconColor.withOpacity(0.3) : AppColors.border,
              width: isExpanded ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? iconColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isExpanded ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForType(item.type),
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'TITIPAN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: iconColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.namaBarang,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                item.namaPenerima,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (item.kelas != null &&
                                  item.kelas!.isNotEmpty) ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  item.kelas!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(item.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand indicator
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            // Type badge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getIconForType(item.type),
                                    size: 16,
                                    color: iconColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jenis: ${_getLabelForType(item.type)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: iconColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Pickup button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _markAsPickedUp(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sudah Diambil',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return '${diff.inDays} hari yang lalu';
    }
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sub FAB: Titipan
        AnimatedBuilder(
          animation: _fabScaleAnimation,
          builder: (context, child) {
            final scaleValue = _fabScaleAnimation.value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: scaleValue,
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: scaleValue,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Titipan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        heroTag: 'fab_titipan',
                        onPressed: _onTitipanTap,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.inventory_2_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Sub FAB: Pengumuman
        AnimatedBuilder(
          animation: _fabScaleAnimation,
          builder: (context, child) {
            final scaleValue = _fabScaleAnimation.value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: scaleValue,
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: scaleValue,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Pengumuman',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        heroTag: 'fab_pengumuman',
                        onPressed: _onPengumumanTap,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.campaign_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Main FAB
        AnimatedBuilder(
          animation: _fabRotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _fabRotationAnimation.value * 3.14159 * 2,
              child: FloatingActionButton(
                heroTag: 'fab_main',
                onPressed: _toggleFab,
                backgroundColor: _isFabExpanded
                    ? AppColors.textSecondary
                    : AppColors.primary,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isFabExpanded
                      ? const Icon(
                          Icons.close,
                          key: ValueKey('close'),
                          color: Colors.white,
                        )
                      : const Icon(
                          Icons.add,
                          key: ValueKey('add'),
                          color: Colors.white,
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Data model for Paket items
class PaketItem {
  final String namaPenerima;
  final String? kelas;
  final String namaBarang;
  final String type; // food, pakaian, surat, drink
  final DateTime createdAt;
  final bool isGuru;

  PaketItem({
    required this.namaPenerima,
    this.kelas,
    required this.namaBarang,
    required this.type,
    required this.createdAt,
    this.isGuru = false,
  });
}
