import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BoardPickerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> boards;
  final ValueChanged<String> onSelect;
  const BoardPickerScreen({
    super.key,
    required this.boards,
    required this.onSelect,
  });

  @override
  State<BoardPickerScreen> createState() => _BoardPickerScreenState();
}

class _BoardPickerScreenState extends State<BoardPickerScreen> {
  late Map<String?, List<Map<String, dynamic>>> _byParent;

  @override
  void initState() {
    super.initState();
    _byParent = {};
    for (final b in widget.boards) {
      final pid = b['parent_id'] as String?;
      _byParent.putIfAbsent(pid, () => []);
      _byParent[pid]!.add(b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roots = _byParent[null] ?? [];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Elige tablero',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              'Tus tableros',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...roots.map((b) => _BoardTile(
                board: b,
                children: _buildChildren(b['id'] as String?),
                onSelect: (id) {
                  widget.onSelect(id);
                  Navigator.pop(context);
                },
              )),
          if (roots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No tienes tableros aún.',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren(String? parentId) {
    final children = _byParent[parentId] ?? [];
    return children
        .map((c) => _BoardTile(
              board: c,
              children: _buildChildren(c['id'] as String?),
              onSelect: (id) {
                widget.onSelect(id);
                Navigator.pop(context);
              },
            ))
        .toList();
  }
}

class _BoardTile extends StatelessWidget {
  final Map<String, dynamic> board;
  final List<Widget> children;
  final ValueChanged<String> onSelect;

  const _BoardTile({
    required this.board,
    required this.children,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final title = board['titulo'] ?? 'Sin título';
    final isPublic = (board['is_public'] ?? false) as bool;
    return ExpansionTile(
      collapsedBackgroundColor: AppColors.card,
      backgroundColor: AppColors.card,
      textColor: AppColors.foreground,
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.mutedForeground,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        isPublic ? 'Público' : 'Privado',
        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      trailing: TextButton(
        onPressed: () => onSelect(board['id'] as String),
        child: const Text('Elegir'),
      ),
      children: children,
    );
  }
}
