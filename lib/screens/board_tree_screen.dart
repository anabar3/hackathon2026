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
  Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _service.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final all = await _service.getTableros(user.id);
      final map = <String?, List<Map<String, dynamic>>>{};
      for (final b in all) {
        final pid = b['parent_id'] as String?;
        map.putIfAbsent(pid, () => []);
        map[pid]!.add(b);
      }
      // sort each list by created_at desc if available
      for (final entry in map.entries) {
        entry.value.sort((a, b) {
          final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        });
      }
      setState(() {
        _byParent = map;
        _expanded = map.entries
            .where((e) => e.key != null && (e.value.isNotEmpty))
            .map((e) => e.key!)
            .toSet();
      });
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
                decoration:
                    const InputDecoration(labelText: 'Descripción (opcional)'),
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
    await widget.onCreateBoard(
      parentId: parentId,
    );
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
                children: [
                  ..._buildList(null, 0),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildList(String? parentId, int depth) {
    final nodes = _byParent[parentId] ?? [];
    if (nodes.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.only(left: depth * 14.0, bottom: 8),
          child: Text(
            depth == 0
                ? 'No tienes tableros. Crea uno con el +.'
                : 'Sin subtableros.',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
        ),
      ];
    }

    final children = <Widget>[];
    for (final node in nodes) {
      final nodeId = node['id'] as String?;
      final isExpanded = nodeId != null && _expanded.contains(nodeId);
      children.add(
        Padding(
          padding: EdgeInsets.only(left: depth * 14.0, bottom: 10),
          child: _BoardTile(
            titulo: node['titulo'] ?? 'Sin título',
            isPublic: (node['is_public'] ?? false) as bool,
            hasChildren: true,
            depth: depth,
            expanded: isExpanded,
            onExpand: nodeId == null ? null : () => _toggleExpand(nodeId),
            onAddChild:
                nodeId == null ? null : () => _createBoard(parentId: nodeId),
          ),
        ),
      );
      if (isExpanded && nodeId != null) {
        children.addAll(_buildList(nodeId, depth + 1));
      }
    }
    return children;
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
          hasChildren ? (expanded ? Icons.folder_open : Icons.folder) : Icons.folder,
          color: AppColors.primary,
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
          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.mutedForeground,
              ),
              onPressed: onExpand,
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: onAddChild,
            ),
          ],
        ),
        onTap: onExpand,
      ),
    );
  }
}
