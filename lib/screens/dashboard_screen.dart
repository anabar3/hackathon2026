import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final List<Board> boards;
  final void Function(Board) onBoardSelect;
  final VoidCallback? onOpenBoardTree;
  final VoidCallback? onCreateBoard;

  const DashboardScreen({
    super.key,
    required this.boards,
    required this.onBoardSelect,
    this.onOpenBoardTree,
    this.onCreateBoard,
  });

  IconData _boardIcon(String icon) {
    switch (icon) {
      case 'palette':
        return Icons.palette_outlined;
      case 'chef_hat':
        return Icons.restaurant_outlined;
      case 'mountain':
        return Icons.landscape_outlined;
      case 'building':
        return Icons.business_outlined;
      case 'book_open':
        return Icons.menu_book_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roots = boards.where((b) => b.parentId == null).toList();
    final pinned = roots.where((b) => b.isPinned).toList();
    final normal = roots.where((b) => !b.isPinned).toList();
    final ordered = [...pinned, ...normal];
    final hasBoards = roots.isNotEmpty;

    return Column(
      children: [
        // Header (Search Bar, Filter, Notification)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: AppColors.background.withAlpha(242),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppColors.mutedForeground,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search pins or boards...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HeaderIconButton(
                    icon: Icons.filter_alt_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      _HeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {},
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 2, color: AppColors.border),
            ],
          ),
        ),

        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.05, 0.9, 1.0], // Fade at top 5% and bottom 10%
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned by you section
                  if (hasBoards) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PINNED BY YOU',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: onOpenBoardTree,
                          child: Row(
                            children: const [
                              Text(
                                'View all',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => onBoardSelect(roots[0]),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.border.withAlpha(100),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (roots[0].coverImage != null)
                                Image.network(
                                  roots[0].coverImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: AppColors.secondary),
                                )
                              else
                                Container(color: AppColors.secondary),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0x88352F20),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            roots[0].name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _PublicBadgeSolid(
                                            isPublic: roots[0].isPublic,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${roots[0].itemCount} items',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
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
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Empty State for missing boards
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.border.withAlpha(100),
                              offset: const Offset(0, 8),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.dashboard_customize_rounded,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Start organizing!',
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your first board to collect your favorite things.',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: onCreateBoard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.primaryForeground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Create Board',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // All boards grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'YOUR BOARDS',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primary,
                        ),
                        onPressed: onCreateBoard,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasBoards)
                    // GridView of Boards
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: roots.length,
                      itemBuilder: (context, i) {
                        final board = roots[i];
                        return GestureDetector(
                          onTap: () => onBoardSelect(board),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.border.withAlpha(100),
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (board.coverImage != null)
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                            child: Image.network(
                                              board.coverImage!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                    _boardIcon(board.icon),
                                                    color: AppColors.primary
                                                        .withAlpha(100),
                                                    size: 32,
                                                  ),
                                            ),
                                          )
                                        else
                                          Icon(
                                            _boardIcon(board.icon),
                                            color: AppColors.primary.withAlpha(
                                              100,
                                            ),
                                            size: 32,
                                          ),
                                        Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Row(
                                          children: [
                                            if (board.isPinned)
                                              const Icon(Icons.push_pin,
                                                  color: AppColors.primary,
                                                  size: 16),
                                            const SizedBox(width: 4),
                                            _PublicBadgeSolid(
                                              isPublic: board.isPublic,
                                              compact: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(height: 3, color: AppColors.border),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          board.name,
                                          style: const TextStyle(
                                            color: AppColors.foreground,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                              child: const Text(
                                                'For You',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .secondaryForeground,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${board.itemCount} items',
                                              style: const TextStyle(
                                                color:
                                                    AppColors.mutedForeground,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Icon(icon, color: AppColors.foreground, size: 22),
      ),
    );
  }
}

class _PublicBadgeSolid extends StatelessWidget {
  final bool isPublic;
  final bool compact;
  const _PublicBadgeSolid({required this.isPublic, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: compact ? 1 : 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock_outline,
            size: compact ? 10 : 12,
            color: AppColors.foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardsGrid extends StatelessWidget {
  final List<Board> boards;
  final void Function(Board) onBoardSelect;
  final bool showPin;

  const _BoardsGrid({
    required this.boards,
    required this.onBoardSelect,
    this.showPin = false,
  });

  IconData _boardIcon(String icon) {
    switch (icon) {
      case 'palette':
        return Icons.palette_outlined;
      case 'chef_hat':
        return Icons.restaurant_outlined;
      case 'mountain':
        return Icons.landscape_outlined;
      case 'building':
        return Icons.business_outlined;
      case 'book_open':
        return Icons.menu_book_outlined;
      default:
        return Icons.dashboard_customize;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: boards.length,
      itemBuilder: (context, i) {
        final board = boards[i];
        return GestureDetector(
          onTap: () => onBoardSelect(board),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.border,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withAlpha(100),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (board.coverImage != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              board.coverImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                _boardIcon(board.icon),
                                color: AppColors.primary.withAlpha(100),
                                size: 32,
                              ),
                            ),
                          )
                        else
                          Icon(
                            _boardIcon(board.icon),
                            color: AppColors.primary.withAlpha(
                              100,
                            ),
                            size: 32,
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              if (showPin || board.isPinned)
                                const Icon(Icons.push_pin,
                                    color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              _PublicBadgeSolid(
                                isPublic: board.isPublic,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 3, color: AppColors.border),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          board.name,
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${board.itemCount} items',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
