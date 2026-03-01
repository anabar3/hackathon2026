import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/animated_entry.dart';
import 'select_my_item_screen.dart';

class PublicBoardScreen extends StatefulWidget {
  final Board board;
  final String ownerName;
  final List<ContentItem> items;
  final List<ContentItem> myItems;
  final List<Board> subboards;
  final void Function(Board)? onSubboardSelect;
  final VoidCallback onBack;
  final void Function(ContentItem) onItemSelect;
  final Future<void> Function(ContentItem) onSuggest;
  final Future<void> Function(ContentItem)? onExport;

  const PublicBoardScreen({
    super.key,
    required this.board,
    required this.ownerName,
    required this.items,
    required this.myItems,
    this.subboards = const [],
    this.onSubboardSelect,
    required this.onBack,
    required this.onItemSelect,
    required this.onSuggest,
    this.onExport,
  });

  @override
  State<PublicBoardScreen> createState() => _PublicBoardScreenState();
}

class _PublicBoardScreenState extends State<PublicBoardScreen> {
  String _activeFilter = 'All';
  final _filters = ['All', 'Images', 'Videos', 'Links', 'Notes'];
  bool _isSuggesting = false;

  List<ContentItem> get _filteredItems {
    final boardItems = widget.items.toList();
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

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PublicBoardHeader(
                    board: widget.board,
                    itemCount: widget.items.length,
                    onBack: widget.onBack,
                    isSuggesting: _isSuggesting,
                    onSuggest: () async {
                      final selected = await Navigator.push<ContentItem>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectMyItemScreen(
                            items: widget.myItems,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                      if (selected != null) {
                        setState(() => _isSuggesting = true);
                        try {
                          await widget.onSuggest(selected);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Suggestion sent!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSuggesting = false);
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  if (widget.subboards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.9,
                                ),
                            itemCount: widget.subboards.length,
                            itemBuilder: (context, i) {
                              final board = widget.subboards[i];
                              return AnimatedEntry(
                                index: i,
                                child: _SubBoardCard(
                                  board: board,
                                  onTap: widget.onSubboardSelect != null
                                      ? () => widget.onSubboardSelect!(board)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Filters
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
                                  color: active
                                      ? AppColors.foreground
                                      : AppColors.border,
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
                  if (items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 40,
                        ),
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
                              ),
                              child: const Icon(
                                Icons.explore_off_rounded,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Empty Board',
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _MasonryGrid(
                        items: items,
                        onItemTap: widget.onItemSelect,
                        onExport: widget.onExport,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  final List<ContentItem> items;
  final void Function(ContentItem) onItemTap;
  final Future<void> Function(ContentItem)? onExport;

  const _MasonryGrid({
    required this.items,
    required this.onItemTap,
    this.onExport,
  });

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
                      child: _ExportableCard(
                        item: entry.value,
                        onTap: () => onItemTap(entry.value),
                        onExport: onExport,
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
                      child: _ExportableCard(
                        item: entry.value,
                        onTap: () => onItemTap(entry.value),
                        onExport: onExport,
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

class _ExportableCard extends StatefulWidget {
  final ContentItem item;
  final VoidCallback onTap;
  final Future<void> Function(ContentItem)? onExport;

  const _ExportableCard({
    required this.item,
    required this.onTap,
    this.onExport,
  });

  @override
  State<_ExportableCard> createState() => _ExportableCardState();
}

class _ExportableCardState extends State<_ExportableCard> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ContentCard(item: widget.item, onTap: widget.onTap),
        if (widget.onExport != null)
          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: _exporting
                  ? null
                  : () async {
                      setState(() => _exporting = true);
                      try {
                        await widget.onExport!(widget.item);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item guardado en tu Inbox ✅'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => _exporting = false);
                      }
                    },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.border, offset: Offset(0, 2)),
                  ],
                ),
                child: _exporting
                    ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.library_add_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SuggestBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SuggestBtn({required this.onTap});

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
        ),
        child: Row(
          children: const [
            Icon(Icons.add_reaction_outlined, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Suggest Item',
              style: TextStyle(
                color: Colors.white,
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
        ),
        child: Icon(icon, color: AppColors.foreground, size: 20),
      ),
    );
  }
}

class _PublicBoardHeader extends StatelessWidget {
  final Board board;
  final int itemCount;
  final VoidCallback onBack;
  final VoidCallback onSuggest;
  final bool isSuggesting;

  const _PublicBoardHeader({
    required this.board,
    required this.itemCount,
    required this.onBack,
    required this.onSuggest,
    this.isSuggesting = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = board.coverImage != null && board.coverImage!.isNotEmpty;

    return Stack(
      children: [
        Transform.scale(
          scale: 1.04,
          alignment: Alignment.topCenter,
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasCover
                      ? Image.network(
                          board.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.secondary),
                        )
                      : Container(color: AppColors.secondary),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.70),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                    isSuggesting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : _SuggestBtn(onTap: onSuggest),
                  ],
                ),
                const Spacer(),
                Text(
                  board.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$itemCount items',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (board.description != null &&
                    board.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    board.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
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
