import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class BoardTreeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Future<void> Function({String? parentId}) onCreateBoard;
  const BoardTreeScreen({
    super.key,
    required this.onBack,
    required this.onCreateBoard,
  });

  @override
  State<BoardTreeScreen> createState() => _BoardTreeScreenState();
}

class _BoardTreeScreenState extends State<BoardTreeScreen> {
  final _service = SupabaseService();
  bool _loading = true;
  Map<String?, List<Map<String, dynamic>>> _byParent = {};
  Map<String?, List<Map<String, dynamic>>> _itemsByBoard = {};
  Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    debugPrint("--- _load() CALLED ---");
    final user = _service.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final all = await _service.getTableros(user.id);
      final allItems = await _service.getItems(user.id);

      debugPrint("--- DEBUG GET ITEMS ---");
      debugPrint("Total tableros Fetched: ${all.length}");
      for (var b in all) {
        debugPrint(
          "Tablero: ${b['titulo']} (ID: ${b['id']}, Parent: ${b['parent_id']})",
        );
      }

      debugPrint("Total items Fetched: ${allItems.length}");
      for (var item in allItems) {
        debugPrint(
          "Item: ${item['titulo']} (Tablero ID: ${item['tablero_id']})",
        );
      }
      debugPrint("-----------------------");

      final map = <String?, List<Map<String, dynamic>>>{};
      for (final b in all) {
        final pid = b['parent_id']?.toString();
        map.putIfAbsent(pid, () => []);
        map[pid]!.add(b);
      }

      final itemsMap = <String?, List<Map<String, dynamic>>>{};
      for (final item in allItems) {
        final tid = item['tablero_id']?.toString();
        itemsMap.putIfAbsent(tid, () => []);
        itemsMap[tid]!.add(item);
      }

      // sort each list by created_at desc if available
      for (final entry in map.entries) {
        entry.value.sort((a, b) {
          final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        });
      }

      for (final entry in itemsMap.entries) {
        entry.value.sort((a, b) {
          final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        });
      }

      setState(() {
        _byParent = map;
        _itemsByBoard = itemsMap;
        _expanded = map.entries
            .where((e) => e.key != null && (e.value.isNotEmpty))
            .map((e) => e.key!)
            .toSet();
      });
    } catch (e, stack) {
      debugPrint('Error loading boards: $e\n$stack');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleExpand(String boardId) async {
    final nowExpanded = !_expanded.contains(boardId);
    setState(() {
      if (nowExpanded) {
        _expanded.add(boardId);
      } else {
        _expanded.remove(boardId);
      }
    });
  }

  Future<void> _createBoard({String? parentId}) async {
    final user = _service.currentUser;
    if (user == null) return;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Nuevo tablero'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isPublic,
                    onChanged: (v) {
                      isPublic = v ?? false;
                      setState(() {});
                    },
                  ),
                  const Text('Público'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
    if (created != true) return;
    await widget.onCreateBoard(parentId: parentId);
    await _load();
    if (parentId != null) _expanded.add(parentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Tableros',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _createBoard(parentId: null),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [..._buildList(null, 0)],
              ),
            ),
    );
  }

  List<Widget> _buildList(String? parentId, int depth) {
    final nodes = _byParent[parentId] ?? [];
    final items = _itemsByBoard[parentId] ?? [];

    if (nodes.isEmpty && items.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.only(left: depth * 14.0, bottom: 8),
          child: Text(
            depth == 0 ? 'No tienes tableros ni recursos aquí.' : 'Vacío.',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
        ),
      ];
    }

    final children = <Widget>[];

    // Primero agregamos los tableros hijos
    for (final node in nodes) {
      final nodeId = node['id']?.toString();
      final isExpanded = nodeId != null && _expanded.contains(nodeId);
      final hasChildNodes = _byParent[nodeId]?.isNotEmpty ?? false;
      final hasChildItems = _itemsByBoard[nodeId]?.isNotEmpty ?? false;
      final bool actuallyHasChildren = hasChildNodes || hasChildItems;

      children.add(
        Padding(
          padding: EdgeInsets.only(left: depth * 14.0, bottom: 10),
          child: _BoardTile(
            titulo: node['titulo']?.toString() ?? 'Sin título',
            isPublic: (node['is_public'] ?? false) as bool,
            hasChildren: actuallyHasChildren,
            depth: depth,
            expanded: isExpanded,
            onExpand: nodeId == null ? null : () => _toggleExpand(nodeId),
            onAddChild: nodeId == null
                ? null
                : () => _createBoard(parentId: nodeId),
          ),
        ),
      );
      if (isExpanded && nodeId != null) {
        children.addAll(_buildList(nodeId, depth + 1));
      }
    }

    // Luego agregamos los items (recursos)
    for (final item in items) {
      children.add(
        Padding(
          padding: EdgeInsets.only(left: depth * 14.0, bottom: 10),
          child: _ItemTile(item: item, depth: depth),
        ),
      );
    }

    return children;
  }
}

class _ItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final int depth;

  const _ItemTile({required this.item, required this.depth});

  @override
  Widget build(BuildContext context) {
    final tipo = item['tipo']?.toString();
    final isLink = tipo == 'link';
    final titulo =
        (item['titulo'] ?? (isLink ? item['contenido'] : 'Sin título'))
            ?.toString() ??
        'Sin título';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(
          _getIconForType(tipo),
          color: AppColors.primary.withOpacity(0.8),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  IconData _getIconForType(String? tipo) {
    switch (tipo) {
      case 'texto':
        return Icons.description;
      case 'link':
        return Icons.link;
      case 'imagen':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.video_library;
      case 'archivo':
        return Icons.insert_drive_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _BoardTile extends StatelessWidget {
  final String titulo;
  final bool isPublic;
  final bool hasChildren;
  final bool expanded;
  final int depth;
  final VoidCallback? onExpand;
  final VoidCallback? onAddChild;

  const _BoardTile({
    required this.titulo,
    required this.isPublic,
    required this.hasChildren,
    required this.expanded,
    required this.depth,
    required this.onExpand,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(
          hasChildren
              ? (expanded ? Icons.folder_open : Icons.folder)
              : Icons.folder,
          color: hasChildren
              ? AppColors.primary
              : AppColors.mutedForeground.withOpacity(0.5),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isPublic ? 'Público' : 'Privado',
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasChildren)
              IconButton(
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.mutedForeground,
                ),
                onPressed: onExpand,
              )
            else
              const SizedBox(
                width: 48,
              ), // Spacer to align with items that have expand icon
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: onAddChild,
            ),
          ],
        ),
        onTap: hasChildren ? onExpand : null,
      ),
    );
  }
}
