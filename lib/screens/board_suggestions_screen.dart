import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/animated_entry.dart';

class BoardSuggestionsScreen extends StatefulWidget {
  final Board board;
  final List<dynamic> suggestions;
  final VoidCallback onBack;
  final Future<void> Function(String suggestionId, bool accept) onResolve;

  const BoardSuggestionsScreen({
    super.key,
    required this.board,
    required this.suggestions,
    required this.onBack,
    required this.onResolve,
  });

  @override
  State<BoardSuggestionsScreen> createState() => _BoardSuggestionsScreenState();
}

class _BoardSuggestionsScreenState extends State<BoardSuggestionsScreen> {
  final Set<String> _resolving = {};

  Future<void> _handleResolve(String suggestionId, bool accept) async {
    setState(() => _resolving.add(suggestionId));
    try {
      await widget.onResolve(suggestionId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Suggestion accepted!' : 'Suggestion rejected.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _resolving.remove(suggestionId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        Icons.arrow_back_rounded,
                        color: AppColors.foreground,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Suggested Items',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: widget.suggestions.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending suggestions.',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.suggestions.length,
                      itemBuilder: (context, index) {
                        final sug = widget.suggestions[index] ?? {};
                        final suggestionId = (sug['id'] ?? '').toString();
                        if (suggestionId.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final itemData =
                            (sug['item'] ?? <String, dynamic>{})
                                as Map<String, dynamic>;
                        final autorData =
                            sug['autor_perfil'] as Map<String, dynamic>?;

                        ContentType _parseType(String? value) {
                          switch ((value ?? '').toLowerCase()) {
                            case 'video':
                              return ContentType.video;
                            case 'link':
                              return ContentType.link;
                            case 'audio':
                              return ContentType.audio;
                            case 'document':
                              return ContentType.document;
                            case 'file':
                            case 'archivo':
                              return ContentType.file;
                            case 'note':
                            case 'texto':
                              return ContentType.note;
                            case 'image':
                            case 'imagen':
                            default:
                              return ContentType.image;
                          }
                        }

                        // Fallback when backend doesn't embed an item map (common for ad-hoc suggestions).
                        final tipoRaw = itemData['tipo'] ?? sug['tipo'];
                        final titleRaw = itemData['titulo'] ?? sug['titulo'];
                        final descRaw =
                            itemData['descripcion'] ?? sug['contenido'];
                        final thumbRaw =
                            itemData['thumbnail_url'] ??
                            (sug['raw_data'] is Map
                                ? (sug['raw_data']['thumbnail'] ??
                                      sug['raw_data']['image'])
                                : null);
                        final urlRaw = itemData['url'] ?? sug['contenido'];

                        final autorName =
                            autorData?['username'] ??
                            autorData?['nombre_completo'] ??
                            'Unknown User';

                        final item = ContentItem(
                          id: (itemData['id'] ?? suggestionId).toString(),
                          type: _parseType(tipoRaw?.toString()),
                          title: (titleRaw ?? 'Untitled').toString(),
                          description: descRaw?.toString(),
                          url: urlRaw?.toString(),
                          thumbnail: thumbRaw?.toString(),
                          boardId: (sug['target_tablero_id'] ?? '').toString(),
                          createdAt:
                              (itemData['created_at'] ??
                                      sug['created_at'] ??
                                      '')
                                  .toString()
                                  .split('T')
                                  .first,
                          duration: null,
                          size: null,
                          tags: const [],
                          author: autorName,
                          saved: false,
                        );

                        final isResolving = _resolving.contains(suggestionId);

                        return AnimatedEntry(
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primary,
                                      backgroundImage:
                                          autorData?['avatar_url'] != null
                                          ? (autorData?['avatar_url']
                                                        .toString()
                                                        .startsWith(
                                                          'assets/',
                                                        ) ==
                                                    true
                                                ? AssetImage(
                                                        autorData?['avatar_url']
                                                                .toString() ??
                                                            '',
                                                      )
                                                      as ImageProvider
                                                : NetworkImage(
                                                    autorData?['avatar_url']
                                                            .toString() ??
                                                        '',
                                                  ))
                                          : null,
                                      child: autorData?['avatar_url'] == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Suggested by $autorName',
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ContentCard(item: item, onTap: () {}),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Reject',
                                        icon: Icons.close_rounded,
                                        color: Colors.redAccent,
                                        isDisabled: isResolving,
                                        onTap: () =>
                                            _handleResolve(suggestionId, false),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Accept',
                                        icon: Icons.check_rounded,
                                        color: AppColors.primary,
                                        isDisabled: isResolving,
                                        onTap: () =>
                                            _handleResolve(suggestionId, true),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                  color: AppColors.border,
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.secondary : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled ? AppColors.border : color,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDisabled)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mutedForeground,
                ),
              )
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? AppColors.mutedForeground : color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
