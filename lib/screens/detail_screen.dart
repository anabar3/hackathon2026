import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final ContentItem item;
  final Board board;
  final VoidCallback onBack;
  final void Function(String) onToggleSaved;
  /// Callback that triggers AI summarization for this item. Should return a
  /// Future that completes when the summary has been stored in Supabase and the
  /// parent state refreshed.
  final Future<void> Function()? onAiSummarize;
  final Future<void> Function(String, String) onUpdateTitle;
  final Future<void> Function(String, String) onUpdateDescription;
  final Future<String> Function(
    String itemId,
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) onUpdateThumbnail;
  final Future<void> Function(String) onDeleteItem;
  final VoidCallback onSummarize;
  final Future<void> Function(Board board, bool toPublic) onToggleVisibility;

  const DetailScreen({
    super.key,
    required this.item,
    required this.board,
    required this.onBack,
    required this.onToggleSaved,
    this.onAiSummarize,
    required this.onUpdateTitle,
    required this.onUpdateDescription,
    required this.onUpdateThumbnail,
    required this.onDeleteItem,
    required this.onSummarize,
    required this.onToggleVisibility,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? _thumbUrl;
  bool _savingTitle = false;
  bool _savingDesc = false;
  bool _deleting = false;
  bool _uploadingThumb = false;
  bool _showAiSummary = false;
  bool _loadingAiSummary = false;

  Future<void> _editTitle() async {
    if (_savingTitle) return;
    final controller = TextEditingController(text: widget.item.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Editar título'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newTitle == null ||
        newTitle.isEmpty ||
        newTitle == widget.item.title) return;

    setState(() => _savingTitle = true);
    try {
      await widget.onUpdateTitle(widget.item.id, newTitle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Título actualizado')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el título')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingTitle = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _thumbUrl = widget.item.thumbnail;
  }

  @override
  void didUpdateWidget(covariant DetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.thumbnail != widget.item.thumbnail) {
      _thumbUrl = widget.item.thumbnail;
      _showAiSummary = false;
      _loadingAiSummary = false;
    }
  }

  Future<void> _editDescription() async {
    if (_savingDesc) return;
    final controller = TextEditingController(text: widget.item.description ?? '');
    final newDesc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Editar descripción'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Añade más contexto (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newDesc == null) return;
    if ((widget.item.description ?? '') == newDesc) return;

    setState(() => _savingDesc = true);
    try {
      await widget.onUpdateDescription(widget.item.id, newDesc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descripción actualizada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la descripción')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDesc = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Seguro que quieres eliminar?'),
          content: const Text(
            'Se eliminará este item. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await widget.onDeleteItem(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item eliminado')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el item')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _pickThumbnail() async {
    if (_uploadingThumb) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.first;
    if (file == null || file.bytes == null) return;
    setState(() => _uploadingThumb = true);
    try {
      final mime =
          file.extension != null ? 'image/${file.extension}' : 'image/jpeg';
      final url = await widget.onUpdateThumbnail(
        widget.item.id,
        file.bytes!,
        file.name,
        mime,
      );
      setState(() => _thumbUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la imagen')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingThumb = false);
    }
  }

  IconData _typeIcon() {
    switch (widget.item.type) {
      case ContentType.video:
        return Icons.play_circle_outline;
      case ContentType.link:
        return Icons.link;
      case ContentType.audio:
        return Icons.headphones;
      case ContentType.note:
        return Icons.sticky_note_2_outlined;
      case ContentType.document:
        return Icons.description_outlined;
      case ContentType.file:
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  Future<void> _handleAiSummaryPressed() async {
    // Hide if already visible
    if (_showAiSummary) {
      setState(() => _showAiSummary = false);
      return;
    }

    final hasSummary =
        widget.item.aiSummary != null && widget.item.aiSummary!.isNotEmpty;

    if (!hasSummary && widget.onAiSummarize != null) {
      setState(() => _loadingAiSummary = true);
      try {
        final maybeFuture = widget.onAiSummarize!();
        if (maybeFuture is Future) {
          await maybeFuture;
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo generar el resumen automáticamente'),
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
    final hasImage = _thumbUrl != null && _thumbUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Image Area
                Container(
                  color: AppColors.secondary,
                  height: 320,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage && _thumbUrl != null)
                        Image.network(
                          _thumbUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              _typeIcon(),
                              color: AppColors.primary,
                              size: 64,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            _typeIcon(),
                            color: AppColors.primary,
                            size: 64,
                          ),
                        ),
                      if (hasImage)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Color(0x88352F20),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _MiniEditIcon(
                          onTap: _uploadingThumb ? null : _pickThumbnail,
                          loading: _uploadingThumb,
                        ),
                      ),
                      if (widget.item.type == ContentType.video)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.card,
                                  width: 4,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content Panel overlapping the image
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _typeIcon(),
                                      color: AppColors.primaryForeground,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.item.type.name,
                                      style: const TextStyle(
                                        color: AppColors.primaryForeground,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => widget.onToggleVisibility(
                                  board,
                                  !board.isPublic,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        board.isPublic
                                            ? Icons.public
                                            : Icons.lock_outline,
                                        size: 14,
                                        color: AppColors.mutedForeground,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        board.isPublic ? 'Public' : 'Private',
                                        style: const TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Título',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              _MiniEditIcon(
                                onTap: _savingTitle ? null : _editTitle,
                                loading: _savingTitle,
                              ),
                            ],
                          ),
                          if (widget.item.author != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'by ${widget.item.author}',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(minHeight: 140),
                                  padding: const EdgeInsets.all(4),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      (widget.item.description == null ||
                                              widget.item.description!.isEmpty)
                                          ? 'Añade una descripción'
                                          : widget.item.description!,
                                      style: TextStyle(
                                        color: (widget.item.description == null ||
                                                widget.item.description!.isEmpty)
                                            ? AppColors.mutedForeground
                                            : AppColors.foreground,
                                        fontSize: 15,
                                        height: 1.6,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _MiniEditIcon(
                                onTap: _savingDesc ? null : _editDescription,
                                loading: _savingDesc,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (widget.item.tags.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Row(
                              children: const [
                                Icon(
                                  Icons.sell_rounded,
                                  size: 18,
                                  color: AppColors.mutedForeground,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'TAGS',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.item.tags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],

                          if (widget.item.url != null) ...[
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Open Link',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _loadingAiSummary ? null : _handleAiSummaryPressed,
                                  icon: _loadingAiSummary
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome, size: 20),
                                  label: Text(
                                    _showAiSummary ? 'Ocultar resumen' : 'AI Summary',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _deleting ? null : _confirmDelete,
                                  icon: _deleting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.delete_outline_rounded, size: 20),
                                  label: const Text(
                                    'Delete item',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_showAiSummary) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
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
                                        'AI Summary',
                                        style: TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_loadingAiSummary)
                                        const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_loadingAiSummary)
                                    const Text(
                                      'Generando resumen...',
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else if (widget.item.aiSummary != null &&
                                      widget.item.aiSummary!.isNotEmpty)
                                    Text(
                                      widget.item.aiSummary!,
                                      style: const TextStyle(
                                        color: AppColors.foreground,
                                        fontSize: 15,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Aún no hay un resumen para este item. Pulsa el botón para generarlo.',
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating header
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _SolidBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: widget.onBack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _SolidBtn({required this.icon, required this.onTap, this.color});

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
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: color ?? AppColors.foreground, size: 20),
      ),
    );
  }
}

class _MiniEditIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  const _MiniEditIcon({required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.muted.withAlpha(60),
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.edit_outlined,
                color: AppColors.mutedForeground,
                size: 16,
              ),
      ),
    );
  }
}
