import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/animated_entry.dart';

class BoardScreen extends StatefulWidget {
  final Board board;
  final List<ContentItem> items;
  final List<Board> boards;
  final VoidCallback onBack;
  final void Function(ContentItem) onItemSelect;
  final VoidCallback onEdit;
  final VoidCallback onAiOrganize;

  const BoardScreen({
    super.key,
    required this.board,
    required this.items,
    required this.boards,
    required this.onBack,
    required this.onItemSelect,
    required this.onEdit,
    required this.onAiOrganize,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String _activeFilter = 'All';
  final _filters = ['All', 'Images', 'Videos', 'Links', 'Notes'];

  List<ContentItem> get _filteredItems {
    final boardItems = widget.items
        .where((i) => i.boardId == widget.board.id)
        .toList();
    if (_activeFilter == 'All') return boardItems;
    final typeMap = {
      'Images': ContentType.image,
      'Videos': ContentType.video,
      'Links': ContentType.link,
      'Notes': ContentType.note,
    };
    return boardItems.where((i) => i.type == typeMap[_activeFilter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final childrenBoards = widget.boards
        .where((b) => b.parentId == widget.board.id)
        .toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleBtn(icon: Icons.arrow_back_rounded, onTap: widget.onBack),
              Row(
                children: [
                  _PrimaryBtn(
                    label: 'Sugerencias',
                    icon: Icons.lightbulb_outline,
                    onTap: widget.onAiOrganize,
                  ),
                  const SizedBox(width: 8),
                  _PrimaryBtn(
                    label: 'Editar',
                    icon: Icons.edit_outlined,
                    onTap: widget.onEdit,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Title line
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.board.name,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              _PublicBadge(isPublic: widget.board.isPublic),
            ],
          ),
        ),
        if (childrenBoards.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subtableros',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: childrenBoards.length,
                  itemBuilder: (context, i) {
                    final board = childrenBoards[i];
                    return AnimatedEntry(
                      index: i,
                      child: _SubBoardCard(board: board),
                    );
                  },
                ),
              ],
            ),
          ),

        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: const [
              Text(
                'Items',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final active = f == _activeFilter;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.foreground
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppColors.foreground : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: active
                            ? AppColors.background
                            : AppColors.secondaryForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.border.withAlpha(50),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.explore_off_rounded,
                              color: AppColors.primary,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No items yet',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add some cool stuff here to start building your collection!',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ShaderMask(
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
                      stops: [
                        0.0,
                        0.05,
                        0.9,
                        1.0,
                      ], // Fade at top 5% and bottom 10%
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: _MasonryGrid(
                      items: items,
                      onItemTap: widget.onItemSelect,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  final List<ContentItem> items;
  final void Function(ContentItem) onItemTap;

  const _MasonryGrid({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final left = <ContentItem>[];
    final right = <ContentItem>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        left.add(items[i]);
      } else {
        right.add(items[i]);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnimatedEntry(
                      index: entry.key * 2,
                      child: ContentCard(
                        item: entry.value,
                        onTap: () => onItemTap(entry.value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: right
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnimatedEntry(
                      index: entry.key * 2 + 1,
                      child: ContentCard(
                        item: entry.value,
                        onTap: () => onItemTap(entry.value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SubBoardCard extends StatelessWidget {
  final Board board;
  final VoidCallback? onTap;
  const _SubBoardCard({required this.board, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: board.coverImage != null
                    ? Image.network(board.coverImage!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.secondary,
                        child: Icon(
                          Icons.dashboard_customize,
                          color: AppColors.primary.withAlpha(120),
                          size: 28,
                        ),
                      ),
              ),
            ),
            Container(height: 2, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          board.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (board.isPinned)
                        const Icon(
                          Icons.push_pin,
                          size: 14,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${board.itemCount} items',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

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
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: AppColors.foreground, size: 20),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryForeground, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryForeground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicBadge extends StatelessWidget {
  final bool isPublic;
  const _PublicBadge({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock_outline,
            size: 14,
            color: AppColors.secondaryForeground,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: const TextStyle(
              color: AppColors.secondaryForeground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
