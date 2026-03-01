import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/animated_entry.dart';

class SelectMyItemScreen extends StatefulWidget {
  final List<ContentItem> items;
  final VoidCallback onBack;
  final Future<dynamic> Function()? onCreateNew;

  const SelectMyItemScreen({
    super.key,
    required this.items,
    required this.onBack,
    this.onCreateNew,
  });

  @override
  State<SelectMyItemScreen> createState() => _SelectMyItemScreenState();
}

class _SelectMyItemScreenState extends State<SelectMyItemScreen> {
  String _activeFilter = 'Todos';
  final _filters = ['Todos', 'Imágenes', 'Videos', 'Enlaces', 'Notas'];

  List<ContentItem> get _filteredItems {
    if (_activeFilter == 'Todos') return widget.items;
    final typeMap = {
      'Imágenes': ContentType.image,
      'Videos': ContentType.video,
      'Enlaces': ContentType.link,
      'Notas': ContentType.note,
    };
    return widget.items.where((i) => i.type == typeMap[_activeFilter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.foreground,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Elige un elemento para sugerir',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

            // Items Grid
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron elementos.',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MasonryGrid(
                        items: items,
                        onItemTap: (item) {
                          Navigator.pop(context, item);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.onCreateNew == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final newItem = await widget.onCreateNew!();
                if (newItem != null && context.mounted) {
                  Navigator.pop(context, newItem);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.background),
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
      if (i.isEven)
        left.add(items[i]);
      else
        right.add(items[i]);
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
