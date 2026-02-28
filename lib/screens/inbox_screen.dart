import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InboxScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;

  const InboxScreen({
    super.key,
    required this.items,
    required this.loading,
    required this.onRefresh,
    required this.onAdd,
  });

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'link':
        return Icons.link;
      case 'imagen':
        return Icons.image_outlined;
      case 'audio':
        return Icons.mic_none;
      case 'video':
        return Icons.play_circle_outline;
      case 'archivo':
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.notes_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Inbox',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.primary,
            onPressed: onAdd,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'Tu inbox está vacío',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final tipo = item['tipo'] as String? ?? 'texto';
                        final titulo = item['titulo'] as String?;
                        final contenido = item['contenido'] as String? ?? '';
                        final createdAt = DateTime.tryParse(
                            item['created_at']?.toString() ?? '');
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _iconFor(tipo),
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              titulo?.isNotEmpty == true
                                  ? titulo!
                                  : (tipo == 'texto'
                                      ? contenido
                                      : tipo.toUpperCase()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              contenido,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                            trailing: createdAt == null
                                ? null
                                : Text(
                                    _timeAgo(createdAt),
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
