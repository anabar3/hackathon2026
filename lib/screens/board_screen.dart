import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';

class BoardScreen extends StatefulWidget {
  final Board board;
  final List<ContentItem> items;
  final VoidCallback onBack;
  final void Function(ContentItem) onItemSelect;
  final VoidCallback onEdit;
  final VoidCallback onAiOrganize;

  const BoardScreen({
    super.key,
    required this.board,
    required this.items,
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

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleBtn(icon: Icons.arrow_back, onTap: widget.onBack),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onAiOrganize,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(38),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(64),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CircleBtn(icon: Icons.tune, onTap: () {}),
                  const SizedBox(width: 8),
                  _CircleBtn(icon: Icons.more_horiz, onTap: widget.onEdit),
                ],
              ),
            ],
          ),
        ),
        // Title + filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.board.name,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PublicBadge(isPublic: widget.board.isPublic),
                ],
              ),
              if (widget.board.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.board.description!,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final active = f == _activeFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : AppColors.mutedForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: AppColors.mutedForeground,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No items yet',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Add content to this board',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: _MasonryGrid(
                    items: items,
                    onItemTap: widget.onItemSelect,
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
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ContentCard(
                      item: item,
                      onTap: () => onItemTap(item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: right
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ContentCard(
                      item: item,
                      onTap: () => onItemTap(item),
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.foreground, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock_outline,
            size: 12,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
