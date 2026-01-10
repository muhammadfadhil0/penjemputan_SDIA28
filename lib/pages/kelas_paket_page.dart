import 'package:flutter/material.dart';
import '../main.dart';

// ============================================
// KELAS PAKET PAGE
// Halaman untuk melihat barang titipan yang ditujukan ke kelas ini
// ============================================
class KelasPaketPage extends StatefulWidget {
  const KelasPaketPage({super.key});

  @override
  State<KelasPaketPage> createState() => _KelasPaketPageState();
}

class _KelasPaketPageState extends State<KelasPaketPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for packages - Belum Diambil
  final List<_DummyPaketItem> _pendingItems = [
    _DummyPaketItem(
      id: '1',
      namaBarang: 'Bekal Makan Siang',
      namaPengirim: 'Ibu Sari',
      namaPenerima: 'Ahmad Farhan',
      type: 'food',
      keterangan: 'Bekal makan siang untuk Ahmad, dimakan saat istirahat.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    _DummyPaketItem(
      id: '2',
      namaBarang: 'Baju Olahraga',
      namaPengirim: 'Ayah Budi',
      namaPenerima: 'Budi Santoso',
      type: 'pakaian',
      keterangan: 'Baju olahraga yang tertinggal di rumah.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    _DummyPaketItem(
      id: '3',
      namaBarang: 'Air Mineral',
      namaPengirim: 'Orang Tua Citra',
      namaPenerima: 'Citra Dewi',
      type: 'drink',
      keterangan: 'Botol air minum untuk Citra.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // List untuk paket yang sudah diambil
  final List<_DummyPaketItem> _receivedItems = [];

  // Dummy data for pengumuman
  final List<_DummyPengumumanItem> _pengumumanItems = [
    _DummyPengumumanItem(
      id: 'p1',
      judul: 'Kegiatan Pekan Budaya',
      keterangan:
          'Kegiatan Pekan Budaya akan dilaksanakan pada tanggal 15-20 Januari 2026. Mohon siswa mempersiapkan kostum daerah masing-masing.',
      type: 'info',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    _DummyPengumumanItem(
      id: 'p2',
      judul: 'Perhatian! Jadwal Ujian Berubah',
      keterangan:
          'Ujian tengah semester yang semula dijadwalkan tanggal 25 Januari dipindah ke tanggal 27 Januari 2026.',
      type: 'warning',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
  ];

  // Track expanded card index for each tab
  int? _expandedPendingCardIndex;
  int? _expandedReceivedCardIndex;
  int? _expandedPengumumanCardIndex;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        'Barang titipan untuk kelas',
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
        subtitle: 'Tidak ada barang titipan yang menunggu diambil',
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
        ],
      ),
    );
  }

  Widget _buildPengumumanList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _pengumumanItems.length,
      itemBuilder: (context, index) {
        return _buildPengumumanCard(_pengumumanItems[index], index);
      },
    );
  }

  // ===== PENGUMUMAN CARD =====
  Widget _buildPengumumanCard(_DummyPengumumanItem item, int index) {
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
                              // Oke button only
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _dismissPengumuman(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Oke',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
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

  void _dismissPengumuman(int index) {
    setState(() {
      _pengumumanItems.removeAt(index);
      _expandedPengumumanCardIndex = null;
    });
  }

  // ===== PAKET CARD =====
  Widget _buildPaketCard(
    _DummyPaketItem item,
    int index, {
    required bool isPending,
  }) {
    final isExpanded = isPending
        ? _expandedPendingCardIndex == index
        : _expandedReceivedCardIndex == index;
    final iconColor = AppColors.primary;

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
                            color: isPending
                                ? iconColor.withOpacity(0.15)
                                : const Color(0xFF22C55E).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconForType(item.type),
                            color: isPending
                                ? iconColor
                                : const Color(0xFF22C55E),
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
                          const SizedBox(height: 2),
                          Text(
                            isPending
                                ? _formatTime(item.createdAt)
                                : 'Diterima ${_formatTime(item.receivedAt ?? item.createdAt)}',
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
                              // Tombol Lihat Detail saja (kelas hanya bisa melihat, tidak bisa mengubah status)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _showDetailBottomSheet(item),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.visibility_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Lihat Detail',
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

  void _showDetailBottomSheet(_DummyPaketItem item) {
    final iconColor = AppColors.primary;
    final isReceived = item.receivedAt != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isReceived
                              ? const Color(0xFF22C55E).withOpacity(0.15)
                              : iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getIconForType(item.type),
                          color: isReceived
                              ? const Color(0xFF22C55E)
                              : iconColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isReceived
                                    ? const Color(0xFF22C55E).withOpacity(0.15)
                                    : iconColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isReceived
                                    ? 'SUDAH DITERIMA'
                                    : _getLabelForType(item.type).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isReceived
                                      ? const Color(0xFF22C55E)
                                      : iconColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.namaBarang,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Dikirim oleh',
                    item.namaPengirim,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.school_outlined,
                    'Ditujukan untuk',
                    item.namaPenerima,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time_outlined,
                    'Waktu dititipkan',
                    _formatTime(item.createdAt),
                  ),
                  if (isReceived) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.check_circle_outline,
                      'Waktu diterima',
                      _formatTime(item.receivedAt!),
                      valueColor: const Color(0xFF22C55E),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keterangan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.keterangan,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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
}

// ===== ANIMATING PAKET CARD (for receive animation) =====
class _AnimatingPaketCard extends StatefulWidget {
  final _DummyPaketItem item;
  final VoidCallback onAnimationComplete;

  const _AnimatingPaketCard({
    required this.item,
    required this.onAnimationComplete,
  });

  @override
  State<_AnimatingPaketCard> createState() => _AnimatingPaketCardState();
}

class _AnimatingPaketCardState extends State<_AnimatingPaketCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _greenFade;
  late Animation<double> _textOpacity;
  late Animation<double> _cardHeight;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _greenFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.25, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.42, curve: Curves.easeOut),
      ),
    );

    _cardHeight = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 1.0, curve: Curves.easeInOut),
      ),
    );

    _cardOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.83, curve: Curves.easeOut),
      ),
    );

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
        return Opacity(
          opacity: _cardOpacity.value,
          child: SizeTransition(
            sizeFactor: _cardHeight,
            axisAlignment: -1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  // Card base
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.namaBarang,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Untuk: ${widget.item.namaPenerima}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Green overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF22C55E,
                        ).withOpacity(_greenFade.value * 0.95),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Barang telah diambil!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Model data dummy untuk paket
class _DummyPaketItem {
  final String id;
  final String namaBarang;
  final String namaPengirim;
  final String namaPenerima;
  final String type;
  final String keterangan;
  final DateTime createdAt;
  final DateTime? receivedAt;

  _DummyPaketItem({
    required this.id,
    required this.namaBarang,
    required this.namaPengirim,
    required this.namaPenerima,
    required this.type,
    required this.keterangan,
    required this.createdAt,
    this.receivedAt,
  });
}

// Model data dummy untuk pengumuman
class _DummyPengumumanItem {
  final String id;
  final String judul;
  final String keterangan;
  final String type; // warning, info
  final DateTime createdAt;

  _DummyPengumumanItem({
    required this.id,
    required this.judul,
    required this.keterangan,
    required this.type,
    required this.createdAt,
  });
}
