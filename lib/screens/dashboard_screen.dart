import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/animated_entry.dart';

class DashboardScreen extends StatefulWidget {
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

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _userName;
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final service = SupabaseService();
    final user = service.currentUser;
    if (user != null) {
      try {
        final profile = await service.getPerfil(user.id);
        if (profile != null && mounted) {
          setState(() {
            _userName = profile['nombre_completo'] ?? profile['username'];
            _userAvatar = profile['avatar_url'];
          });
        }
      } catch (_) {}
    }
  }

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
    // 1. Organize boards
    final roots = widget.boards.where((b) => b.parentId == null).toList();
    final pinned = roots.where((b) => b.isPinned).toList();
    final normal = roots.where((b) => !b.isPinned).toList();

    // 2. Identify Hero Board and the rest
    final Board? heroBoard = (pinned.isNotEmpty)
        ? pinned.first
        : (roots.isNotEmpty ? roots.first : null);

    List<Board> otherBoards = [];
    if (heroBoard != null) {
      otherBoards = [...pinned, ...normal]
        ..removeWhere((b) => b.id == heroBoard.id);
    }

    final hasBoards = roots.isNotEmpty;

    return Column(
      children: [
        // Modern Header with decorative background
        Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -20,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(80),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userName != null
                            ? 'Hi, ${_userName!.split(' ').first}'
                            : 'Hi there',
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 32, // Larger h1
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                  if (_userAvatar != null && _userAvatar!.isNotEmpty)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_userAvatar!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.secondaryForeground,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.9, 1.0], // Only fade at the bottom 10%
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Empty State for missing boards
                  if (!hasBoards) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(32),
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
                              onPressed: widget.onCreateBoard,
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
                  ] else ...[
                    // Hero Board
                    if (heroBoard != null)
                      AnimatedEntry(
                        index: 0,
                        child: _HeroBoardCard(
                          board: heroBoard,
                          onSelect: () => widget.onBoardSelect(heroBoard),
                          iconData: _boardIcon(heroBoard.icon),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // "Your Boards" Header
                    if (otherBoards.isNotEmpty || hasBoards)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Boards',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onCreateBoard,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.foreground,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (otherBoards.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Modern Grid
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: otherBoards.length,
                        itemBuilder: (context, i) {
                          final board = otherBoards[i];
                          return AnimatedEntry(
                            index: i + 1,
                            child: _ModernBoardCard(
                              board: board,
                              onSelect: () => widget.onBoardSelect(board),
                              iconData: _boardIcon(board.icon),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBoardCard extends StatelessWidget {
  final Board board;
  final VoidCallback onSelect;
  final IconData iconData;

  const _HeroBoardCard({
    required this.board,
    required this.onSelect,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // Board Image on the right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: board.coverImage != null
                    ? Image.network(
                        board.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackPattern(),
                      )
                    : _fallbackPattern(),
              ),
            ),

            // Text and Button on the left
            Positioned(
              left: 20,
              top: 24,
              bottom: 24,
              right: 150, // Avoid overlapping image
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        board.name,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Display public pin or "Contains X" info
                      Row(
                        children: [
                          if (board.isPinned)
                            const Icon(
                              Icons.push_pin,
                              color: AppColors.primary,
                              size: 14,
                            )
                          else
                            const Text(
                              'Contains',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 12,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${board.itemCount} items',
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Green Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPattern() {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Icon(iconData, size: 48, color: AppColors.mutedForeground),
      ),
    );
  }
}

class _ModernBoardCard extends StatelessWidget {
  final Board board;
  final VoidCallback onSelect;
  final IconData iconData;

  const _ModernBoardCard({
    required this.board,
    required this.onSelect,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: board.coverImage != null
                      ? Image.network(
                          board.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackPattern(),
                        )
                      : _fallbackPattern(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${board.itemCount} items',
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (board.isPinned)
                        const Icon(
                          Icons.push_pin,
                          color: AppColors.primary,
                          size: 14,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPattern() {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Icon(iconData, size: 36, color: AppColors.primary.withAlpha(50)),
      ),
    );
  }
}
