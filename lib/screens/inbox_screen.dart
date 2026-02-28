import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ai_suggestion.dart';
import '../services/groq_service.dart';
import '../services/supabase_service.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/animated_entry.dart';
import 'board_picker_screen.dart';

class InboxScreen extends StatefulWidget {
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
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _supabaseService = SupabaseService();
  final _groqService = GroqService();

  bool _analyzing = false;
  Map<String, ItemSuggestion> _suggestions = {};
  List<Map<String, dynamic>> _boards = [];

  @override
  void initState() {
    super.initState();
    _analyzeInbox();
  }

  @override
  void didUpdateWidget(InboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _analyzeInbox();
    }
  }

  Future<void> _analyzeInbox() async {
    if (widget.items.isEmpty) return;
    setState(() => _analyzing = true);
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final boards = await _supabaseService.getTableros(user.id);
      if (mounted) {
        setState(() => _boards = boards);
      }
      final aiResponse = await _groqService.analyzeInbox(boards, widget.items);

      final newSuggestions = <String, ItemSuggestion>{};
      for (var s in aiResponse.suggestions) {
        if (s.action != 'none') {
          newSuggestions[s.itemId] = s;
        }
      }
      if (mounted) {
        setState(() => _suggestions = newSuggestions);
      }
    } catch (e) {
      debugPrint('Error analyzing inbox: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _applySuggestion(ItemSuggestion suggestion) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      String? tableroId = suggestion.boardId;

      if (suggestion.action == 'create_new' &&
          suggestion.newBoardSuggestion != null) {
        await _supabaseService.crearTablero(
          userId: user.id,
          titulo: suggestion.newBoardSuggestion!.name,
          descripcion: suggestion.newBoardSuggestion!.description,
        );
        final boards = await _supabaseService.getTableros(user.id);
        final newBoard = boards.firstWhere(
          (b) => b['titulo'] == suggestion.newBoardSuggestion!.name,
          orElse: () => <String, dynamic>{},
        );
        tableroId = newBoard['id'] as String?;
      }

      if (tableroId != null) {
        await _supabaseService.moverItem(
          itemId: suggestion.itemId,
          nuevoTableroId: tableroId,
        );

        setState(() {
          _suggestions.remove(suggestion.itemId);
        });
        await widget.onRefresh();
      }
    } catch (e) {
      debugPrint('Error applying suggestion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al aplicar: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inbox',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                      letterSpacing: -1.0,
                    ),
                  ),
                  if (_analyzing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Drop anything here — AI will organize it',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Large Drop Zone ───
              GestureDetector(
                onTap: widget.onAdd,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Añadir al Inbox',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Links, notas, fotos, audios, archivos...',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quick action row
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.link,
                    label: 'Link',
                    onTap: widget.onAdd,
                  ),
                  const SizedBox(width: 8),
                  _QuickAction(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Nota',
                    onTap: widget.onAdd,
                  ),
                  const SizedBox(width: 8),
                  _QuickAction(
                    icon: Icons.attach_file_rounded,
                    label: 'Archivo',
                    onTap: widget.onAdd,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Items Section ───
              if (widget.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (widget.items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        color: AppColors.mutedForeground.withAlpha(120),
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tu inbox está vacío',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'PENDIENTES (${widget.items.length})',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final itemId = item['id'] as String;
                  final tipo = item['tipo'] as String? ?? 'texto';
                  final titulo = item['titulo'] as String?;
                  final contenido = item['contenido'] as String? ?? '';
                  final createdAt = DateTime.tryParse(
                    item['created_at']?.toString() ?? '',
                  );
                  final hasImagePreview =
                      tipo == 'imagen' && contenido.startsWith('http');

                  final suggestion = _suggestions[itemId];
                  String actionText = '';
                  if (suggestion != null) {
                    if (suggestion.action == 'create_new') {
                      actionText =
                          '✨ Crear tablero "${suggestion.newBoardSuggestion?.name ?? ''}"';
                    } else {
                      final bName = _boards.firstWhere(
                        (b) => b['id'] == suggestion.boardId,
                        orElse: () => {'titulo': 'Tablero'},
                      )['titulo'];
                      actionText = '✨ Mover a "$bName"';
                    }
                  }

                  return AnimatedEntry(
                    index: entry.key,
                    child: Dismissible(
                      key: Key(itemId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (direction) async {
                        try {
                          await _supabaseService.eliminarItem(itemId);
                          setState(() {
                            _suggestions.remove(itemId);
                          });
                          await widget.onRefresh();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al eliminar: $e')),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasImagePreview)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 16 / 10,
                                      child: Image.network(
                                        contenido,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.muted.withAlpha(40),
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: AppColors.mutedForeground,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.card.withAlpha(220),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Text(
                                          'Imagen',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
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
                                hasImagePreview ? 'Foto adjunta' : contenido,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: TextButton.icon(
                                onPressed: () => _pickBoardAndMove(itemId),
                                icon: const Icon(
                                  Icons.drive_file_move_outline,
                                  size: 18,
                                ),
                                label: const Text('Mover'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ),
                            if (suggestion != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: SuggestionCard(
                                  suggestion: suggestion,
                                  actionText: actionText,
                                  onConfirm: () => _applySuggestion(suggestion),
                                  onDismiss: () {
                                    setState(() {
                                      _suggestions.remove(itemId);
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
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

  Future<void> _pickBoardAndMove(String itemId) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;
    // refresh boards to be sure
    final boards = await _supabaseService.getTableros(user.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoardPickerScreen(
          boards: boards,
          onSelect: (boardId) async {
            await _supabaseService.moverItem(
              itemId: itemId,
              nuevoTableroId: boardId,
            );
            await widget.onRefresh();
          },
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
