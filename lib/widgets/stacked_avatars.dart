import 'package:flutter/material.dart';
import '../services/auth/user_model.dart';
import '../services/auth/multi_account_service.dart';
import '../main.dart';

/// Widget untuk menampilkan foto profil bertumpuk (stacked) dengan animasi
/// Akun aktif selalu di depan dengan animasi swap
class StackedAvatars extends StatefulWidget {
  final List<SiswaUser> accounts;
  final double size;
  final double overlapFactor;
  final int maxVisible;
  final VoidCallback? onTap;

  const StackedAvatars({
    super.key,
    required this.accounts,
    this.size = 56,
    this.overlapFactor = 0.35,
    this.maxVisible = 3,
    this.onTap,
  });

  @override
  State<StackedAvatars> createState() => _StackedAvatarsState();
}

class _StackedAvatarsState extends State<StackedAvatars>
    with TickerProviderStateMixin {
  late AnimationController _swapController;
  late Animation<double> _swapAnimation;

  int? _previousActiveId;
  final MultiAccountService _multiAccountService = MultiAccountService();

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _swapAnimation = CurvedAnimation(
      parent: _swapController,
      curve: Curves.easeOutBack,
    );
    _previousActiveId = _multiAccountService.activeAccountId;
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StackedAvatars oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if active account changed
    final currentActiveId = _multiAccountService.activeAccountId;
    if (_previousActiveId != currentActiveId && currentActiveId != null) {
      _swapController.forward(from: 0);
      _previousActiveId = currentActiveId;
    }
  }

  /// Sort accounts so active account is always first
  List<SiswaUser> _getSortedAccounts() {
    if (widget.accounts.isEmpty) return [];

    final activeId = _multiAccountService.activeAccountId;
    if (activeId == null) return widget.accounts;

    final sorted = List<SiswaUser>.from(widget.accounts);
    final activeIndex = sorted.indexWhere((acc) => acc.id == activeId);

    if (activeIndex > 0) {
      final activeAccount = sorted.removeAt(activeIndex);
      sorted.insert(0, activeAccount);
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return _buildDefaultAvatar();
    }

    if (widget.accounts.length == 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: _buildSingleAvatar(widget.accounts.first),
      );
    }

    // Sort so active is first
    final sortedAccounts = _getSortedAccounts();
    final visibleAccounts = sortedAccounts.take(widget.maxVisible).toList();
    final extraCount = widget.accounts.length - widget.maxVisible;
    final overlapOffset = widget.size * widget.overlapFactor;

    // Calculate total width
    final totalWidth =
        widget.size +
        (overlapOffset * (visibleAccounts.length - 1)) +
        (extraCount > 0 ? 20 : 0);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _swapAnimation,
        builder: (context, child) {
          return SizedBox(
            width: totalWidth,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Render avatars - back to front (last index first, then decreasing)
                for (int i = visibleAccounts.length - 1; i >= 0; i--)
                  _buildAnimatedAvatar(
                    visibleAccounts[i],
                    i,
                    visibleAccounts.length,
                    overlapOffset,
                  ),
                // Extra count badge
                if (extraCount > 0)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '+$extraCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedAvatar(
    SiswaUser user,
    int index,
    int totalVisible,
    double overlapOffset,
  ) {
    final isFirst = index == 0;
    final avatarSize = widget.size * (isFirst ? 1.0 : 0.85);

    // Animation values for swap effect
    double scale = 1.0;
    double elevation = isFirst ? 8.0 : 2.0;

    if (isFirst && _swapController.isAnimating) {
      // Active avatar: scale up slightly then back to normal
      final scaleValue = _swapAnimation.value;
      scale =
          1.0 + (0.15 * (1.0 - (scaleValue - 0.5).abs() * 2).clamp(0.0, 1.0));
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      left: index * overlapOffset,
      top: isFirst ? 0 : (widget.size - avatarSize) / 2,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isFirst ? AppColors.primary : Colors.white,
              width: isFirst ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isFirst
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: elevation,
                offset: Offset(0, elevation / 2),
                spreadRadius: isFirst ? 1 : 0,
              ),
            ],
          ),
          child: ClipOval(child: _buildAvatarImage(user)),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLighter,
        border: Border.all(color: AppColors.primaryLight, width: 2),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: widget.size * 0.5,
      ),
    );
  }

  Widget _buildSingleAvatar(SiswaUser user) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarImage(user)),
    );
  }

  Widget _buildAvatarImage(SiswaUser user) {
    if (user.fotoUrl != null && user.fotoUrl!.isNotEmpty) {
      return Image.network(
        user.fotoUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.primaryLighter,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primaryLighter,
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: widget.size * 0.4,
            ),
          );
        },
      );
    }

    return Container(
      color: AppColors.primaryLighter,
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: widget.size * 0.4,
      ),
    );
  }
}
