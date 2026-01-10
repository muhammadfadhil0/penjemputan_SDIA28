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
    with TickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;

  // FAB expansion state
  bool _isFabExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabRotationAnimation;
  late Animation<double> _fabScaleAnimation;

  // Data for packages
  final List<PaketItem> _pendingItems = [];
  final List<PaketItem> _receivedItems = [];
  final List<PengumumanItem> _pengumumanItems = [];

  // Track expanded card index for each tab
  int? _expandedPendingCardIndex;
  int? _expandedReceivedCardIndex;
  int? _expandedPengumumanCardIndex;

  // Track animating card
  int? _animatingCardIndex;

  // Track section visibility
  bool _isPengumumanExpanded = true;
  bool _isTitipanExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Reset expanded card when switching tabs
      setState(() {
        _expandedPendingCardIndex = null;
        _expandedReceivedCardIndex = null;
        _expandedPengumumanCardIndex = null;
      });
    });

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
    _tabController.dispose();
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
              _pendingItems.insert(0, item);
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

  void _toggleCardExpansion(int index, bool isPending) {
    setState(() {
      _expandedPengumumanCardIndex = null;
      if (isPending) {
        if (_expandedPendingCardIndex == index) {
          _expandedPendingCardIndex = null;
        } else {
          _expandedPendingCardIndex = index;
        }
      } else {
        if (_expandedReceivedCardIndex == index) {
          _expandedReceivedCardIndex = null;
        } else {
          _expandedReceivedCardIndex = index;
        }
      }
    });
  }

  void _togglePengumumanExpansion(int index) {
    setState(() {
      if (_expandedPengumumanCardIndex == index) {
        _expandedPengumumanCardIndex = null;
      } else {
        _expandedPengumumanCardIndex = index;
        _expandedPendingCardIndex = null;
      }
    });
  }

  void _markAsPickedUp(int index) {
    setState(() {
      _animatingCardIndex = index;
      _expandedPendingCardIndex = null;
    });
  }

  void _dismissPengumuman(int index) {
    setState(() {
      _pengumumanItems.removeAt(index);
      _expandedPengumumanCardIndex = null;
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
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

              const SizedBox(height: 16),

              // Tab Bar
              _buildTabBar(),

              const SizedBox(height: 8),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Belum Diambil
                    _buildPendingTab(),
                    // Tab 2: Sudah Diambil
                    _buildReceivedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildExpandableFab(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Belum Diambil${_pendingItems.isNotEmpty || _pengumumanItems.isNotEmpty ? ' (${_pendingItems.length + _pengumumanItems.length})' : ''}',
              ),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Sudah Diambil${_receivedItems.isNotEmpty ? ' (${_receivedItems.length})' : ''}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    final hasPaket = _pendingItems.isNotEmpty;
    final hasPengumuman = _pengumumanItems.isNotEmpty;

    if (!hasPaket && !hasPengumuman) {
      return _buildEmptyState(
        icon: Icons.inbox_rounded,
        title: 'Belum ada paket',
        subtitle: 'Tekan tombol + untuk menambah titipan\natau pengumuman baru',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // ===== PENGUMUMAN SECTION =====
        if (hasPengumuman) ...[
          _buildSectionHeader(
            title: 'Pengumuman',
            count: _pengumumanItems.length,
            isExpanded: _isPengumumanExpanded,
            onTap: () {
              setState(() {
                _isPengumumanExpanded = !_isPengumumanExpanded;
              });
            },
            color: AppColors.primary,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPengumumanExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                for (int i = 0; i < _pengumumanItems.length; i++)
                  _buildPengumumanCard(_pengumumanItems[i], i),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ],
        // ===== TITIPAN SECTION =====
        if (hasPaket) ...[
          _buildSectionHeader(
            title: 'Paket Titipan',
            count: _pendingItems.length,
            isExpanded: _isTitipanExpanded,
            onTap: () {
              setState(() {
                _isTitipanExpanded = !_isTitipanExpanded;
              });
            },
            color: AppColors.primary,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isTitipanExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                for (int i = 0; i < _pendingItems.length; i++)
                  _buildPaketCard(_pendingItems[i], i, isPending: true),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
        // Extra space for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(height: 1, color: color.withOpacity(0.3)),
              ),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: isExpanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedTab() {
    if (_receivedItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Belum ada riwayat',
        subtitle: 'Paket yang sudah diterima akan muncul di sini',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _receivedItems.length,
      itemBuilder: (context, index) {
        return _buildPaketCard(_receivedItems[index], index, isPending: false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  // ===== PENGUMUMAN CARD =====
  Widget _buildPengumumanCard(PengumumanItem item, int index) {
    final isExpanded = _expandedPengumumanCardIndex == index;
    final isWarning = item.type == 'warning';
    final iconColor = isWarning ? const Color(0xFFF59E0B) : AppColors.primary;
    final icon = isWarning ? Icons.warning_rounded : Icons.info_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _togglePengumumanExpansion(index),
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
                              isWarning ? 'PERINGATAN' : 'PENGUMUMAN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.judul,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
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
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
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
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: iconColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  item.keterangan,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Delete button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _dismissPengumuman(index),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== PAKET CARD =====
  Widget _buildPaketCard(PaketItem item, int index, {required bool isPending}) {
    final isExpanded = isPending
        ? _expandedPendingCardIndex == index
        : _expandedReceivedCardIndex == index;
    final isAnimating = isPending && _animatingCardIndex == index;
    final iconColor = isPending
        ? _getColorForType(item.type)
        : const Color(0xFF22C55E);

    if (isAnimating) {
      return _AnimatingPaketCard(
        item: item,
        getIconForType: _getIconForType,
        onAnimationComplete: () {
          final receivedItem = PaketItem(
            namaPenerima: item.namaPenerima,
            kelas: item.kelas,
            namaBarang: item.namaBarang,
            type: item.type,
            createdAt: item.createdAt,
            isGuru: item.isGuru,
            imagePath: item.imagePath,
          );

          setState(() {
            _pendingItems.removeAt(index);
            _receivedItems.insert(0, receivedItem);
            _animatingCardIndex = null;
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleCardExpansion(index, isPending),
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
                    Stack(
                      children: [
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
                        if (!isPending)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF22C55E),
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF22C55E,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DITERIMA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF22C55E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Text(
                            item.namaPenerima,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getIconForType(item.type),
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.namaBarang,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (item.kelas != null && item.kelas!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.kelas!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isPending
                                  ? AppColors.textMuted
                                  : const Color(0xFF22C55E),
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
              // Expanded content with action buttons
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
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
                              if (isPending)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
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

// Animating card widget for transition effect
class _AnimatingPaketCard extends StatefulWidget {
  final PaketItem item;
  final IconData Function(String) getIconForType;
  final VoidCallback onAnimationComplete;

  const _AnimatingPaketCard({
    required this.item,
    required this.getIconForType,
    required this.onAnimationComplete,
  });

  @override
  State<_AnimatingPaketCard> createState() => _AnimatingPaketCardState();
}

class _AnimatingPaketCardState extends State<_AnimatingPaketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF22C55E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.namaPenerima,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Berhasil diambil!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF22C55E),
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
          ),
        );
      },
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
  final String? imagePath; // Path to attached photo

  PaketItem({
    required this.namaPenerima,
    this.kelas,
    required this.namaBarang,
    required this.type,
    required this.createdAt,
    this.isGuru = false,
    this.imagePath,
  });
}
