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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pinned.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'PINNED',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Icon(Icons.push_pin, color: AppColors.primary, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BoardsGrid(
                    boards: pinned,
                    onBoardSelect: onBoardSelect,
                    showPin: true,
                  ),
                  const SizedBox(height: 24),
                ] else if (!hasBoards) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dashboard_customize,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Crea tu primer tablero para empezar a organizar.',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: onCreateBoard,
                          child: const Text(
                            'Crear',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
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
                    itemCount: ordered.length,
                    itemBuilder: (context, i) {
                      final board = ordered[i];
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
                                            errorBuilder: (_, __, ___) => Icon(
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
                                            padding: const EdgeInsets.symmetric(
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
                                              color: AppColors.mutedForeground,
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
