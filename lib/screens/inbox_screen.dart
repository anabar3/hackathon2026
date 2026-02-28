import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ai_suggestion.dart';
import '../services/groq_service.dart';
import '../services/supabase_service.dart';
import '../widgets/suggestion_card.dart';

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

  @override
  void initState() {
    super.initState();
    _analyzeInbox();
  }

  @override
  void didUpdateWidget(InboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Optionally trigger analysis again if items list fundamentally changes
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
        tableroId = await _supabaseService.crearTableroConRetornoId(
          userId: user.id,
          titulo: suggestion.newBoardSuggestion!.name,
          descripcion: suggestion.newBoardSuggestion!.description,
        );
      }

      if (tableroId != null) {
        await _supabaseService.aplicarSugerencia(
          itemId: suggestion.itemId,
          tableroId: tableroId,
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
          if (_analyzing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.primary,
            onPressed: widget.onAdd,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppColors.primary,
          child: widget.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : widget.items.isEmpty
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
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final itemId = item['id'] as String;
                    final tipo = item['tipo'] as String? ?? 'texto';
                    final titulo = item['titulo'] as String?;
                    final contenido = item['contenido'] as String? ?? '';
                    final createdAt = DateTime.tryParse(
                      item['created_at']?.toString() ?? '',
                    );

                    final suggestion = _suggestions[itemId];

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
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
                          if (suggestion != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: SuggestionCard(
                                suggestion: suggestion,
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
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAdd,
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
