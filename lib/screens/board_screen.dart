import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/animated_entry.dart';
import '../widgets/fade_scroll.dart';

class BoardScreen extends StatefulWidget {
  final Board board;
  final List<ContentItem> items;
  final List<Board> boards;
  final VoidCallback onBack;
  final void Function(Board) onBoardSelect;
  final void Function(ContentItem) onItemSelect;
  final VoidCallback onEdit;
  final void Function(String parentId) onCreateSubBoard;
  final void Function(String boardId) onCreateItem;
  final Future<void> Function() onAiSummarize;
  final VoidCallback onOpenSuggestions;
  final Future<void> Function(Board board, bool toPublic) onToggleVisibility;

  const BoardScreen({
    super.key,
    required this.board,
    required this.items,
    required this.boards,
    required this.onBack,
    required this.onBoardSelect,
    required this.onItemSelect,
    required this.onEdit,
    required this.onCreateSubBoard,
    required this.onCreateItem,
    required this.onAiSummarize,
    required this.onOpenSuggestions,
    required this.onToggleVisibility,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String _activeFilter = 'Todos';
  final _filters = ['Todos', 'Imágenes', 'Videos', 'Enlaces', 'Notas'];
  bool _showAiSummary = false;
  bool _loadingAiSummary = false;

  List<ContentItem> get _filteredItems {
    final boardItems = widget.items
        .where((i) => i.boardId == widget.board.id)
        .toList();
    if (_activeFilter == 'Todos') return boardItems;
    final typeMap = {
      'Imágenes': ContentType.image,
      'Videos': ContentType.video,
      'Enlaces': ContentType.link,
      'Notas': ContentType.note,
    };
    return boardItems.where((i) => i.type == typeMap[_activeFilter]).toList();
  }

  @override
  void didUpdateWidget(covariant BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board.id != widget.board.id) {
      _showAiSummary = false;
      _loadingAiSummary = false;
    }
  }

  Future<void> _handleAiSummaryPressed() async {
    if (_showAiSummary) {
      setState(() => _showAiSummary = false);
      return;
    }

    final hasSummary =
        widget.board.aiSummary != null && widget.board.aiSummary!.isNotEmpty;

    if (!hasSummary) {
      setState(() => _loadingAiSummary = true);
      try {
        await widget.onAiSummarize();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo generar el resumen del tablero'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loadingAiSummary = false);
      }
    }

    if (mounted) setState(() => _showAiSummary = true);
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final items = _filteredItems;
    final allBoardItems = widget.items
        .where((i) => i.boardId == widget.board.id)
        .toList();
    final childrenBoards = widget.boards
        .where((b) => b.parentId == widget.board.id)
        .toList();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FadeScrollView(
            topFade: 0.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BoardHeader(
                      board: board,
                      itemCount: allBoardItems.length,
                      onBack: widget.onBack,
                      onAiSummarize: _handleAiSummaryPressed,
                      onEdit: widget.onEdit,
                      onOpenSuggestions: widget.onOpenSuggestions,
                      onToggleVisibility: () =>
                          widget.onToggleVisibility(board, !board.isPublic),
                    ),
                    if (_showAiSummary)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _AiSummaryCard(
                          summary: board.aiSummary,
                          loading: _loadingAiSummary,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                                onPressed: () =>
                                    widget.onCreateSubBoard(widget.board.id),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Nuevo',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (childrenBoards.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: Text(
                                  'Sin subtableros aún',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
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
                              itemCount: childrenBoards.length,
                              itemBuilder: (context, i) {
                                final board = childrenBoards[i];
                                return AnimatedEntry(
                                  index: i,
                                  child: _SubBoardCard(
                                    board: board,
                                    onTap: () => widget.onBoardSelect(board),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Elementos',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            onPressed: () =>
                                widget.onCreateItem(widget.board.id),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Nuevo',
                              style: TextStyle(fontWeight: FontWeight.w700),
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
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
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
                                  'Aún no hay elementos',
                                  style: TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Añade algo aquí para empezar tu colección.',
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
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _MasonryGrid(
                          items: items,
                          onItemTap: widget.onItemSelect,
                        ),
                      ),
                  ],
                ),
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
                    '${board.itemCount} elementos',
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

class _GroupIdeaBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _GroupIdeaBtn({required this.onTap});

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
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withAlpha(100),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.groups_rounded,
                color: AppColors.foreground,
                size: 20,
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  size: 11,
                  color: AppColors.primaryForeground,
                ),
              ),
            ),
          ],
        ),
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

class _AiSummaryCard extends StatelessWidget {
  final String? summary;
  final bool loading;

  const _AiSummaryCard({required this.summary, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.border, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Resumen IA',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Text(
              'Generando resumen...',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (summary != null && summary!.isNotEmpty)
            Text(
              summary!,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const Text(
              'Aún no hay un resumen para este tablero. Pulsa el botón para generarlo.',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
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
            isPublic ? 'Público' : 'Privado',
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

class _BoardHeader extends StatelessWidget {
  final Board board;
  final int itemCount;
  final VoidCallback onBack;
  final VoidCallback onAiSummarize;
  final VoidCallback onEdit;
  final VoidCallback onOpenSuggestions;
  final VoidCallback onToggleVisibility;

  const _BoardHeader({
    required this.board,
    required this.itemCount,
    required this.onBack,
    required this.onAiSummarize,
    required this.onEdit,
    required this.onOpenSuggestions,
    required this.onToggleVisibility,
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
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              border: Border.all(color: Colors.transparent, width: 0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withAlpha(80),
                  offset: const Offset(0, 4),
                ),
              ],
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
                        stops: const [0.0, 1.0],
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
                    Row(
                      children: [
                        _GroupIdeaBtn(onTap: onOpenSuggestions),
                        const SizedBox(width: 8),
                        _PrimaryBtn(
                          label: 'Resumen IA',
                          icon: Icons.auto_awesome,
                          onTap: onAiSummarize,
                        ),
                        const SizedBox(width: 8),
                        _PrimaryBtn(
                          label: 'Editar',
                          icon: Icons.edit_outlined,
                          onTap: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  board.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onToggleVisibility,
                      child: _PublicBadge(isPublic: board.isPublic),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$itemCount elementos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                      height: 1.3,
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
