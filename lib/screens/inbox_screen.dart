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
            fontWeight: FontWeight.w800,
            fontSize: 24,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final tipo = item['tipo'] as String? ?? 'texto';
                    final titulo = item['titulo'] as String?;
                    final contenido = item['contenido'] as String? ?? '';
                    final createdAt = DateTime.tryParse(
                      item['created_at']?.toString() ?? '',
                    );

                    // Fake suggestion logic based on screenshot
                    final bool hasSuggestion = index < 3;
                    final String suggestionTitle = index == 0
                        ? 'Sugerencia: Nuevo Tablero'
                        : 'Sugerencia: Archivar';
                    final String suggestionAction = index == 0
                        ? 'Crear "Subnautica" y mover aquí.'
                        : 'Mover al tablero recomendado.';
                    final String suggestionDesc = index == 0
                        ? 'El contenido hace referencia a un juego y criaturas del mismo'
                        : 'El contenido menciona criaturas que podrían estar relacionadas con verduras o juegos';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Parent Item Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.menu_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titulo?.isNotEmpty == true
                                            ? titulo!
                                            : (tipo == 'texto'
                                                  ? contenido
                                                  : tipo.toUpperCase()),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      Text(
                                        contenido,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (createdAt != null)
                                  Text(
                                    _timeAgo(createdAt),
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // AI Suggestion Box
                          if (hasSuggestion)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background.withAlpha(200),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(100),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: AppColors.accent,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          suggestionTitle,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.close,
                                        color: AppColors.mutedForeground,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    suggestionAction,
                                    style: const TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    suggestionDesc,
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Confirmar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
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
