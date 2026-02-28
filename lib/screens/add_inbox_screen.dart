import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class AddInboxScreen extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function() onSaved;
  const AddInboxScreen({
    super.key,
    required this.onClose,
    required this.onSaved,
  });

  @override
  State<AddInboxScreen> createState() => _AddInboxScreenState();
}

class _AddInboxScreenState extends State<AddInboxScreen> {
  final _service = SupabaseService();
  final _controller = TextEditingController();
  final _titleController = TextEditingController();
  bool _saving = false;
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  String? _pickedMime;
  String? _pickedTipo;

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final hasFile = _pickedBytes != null && _pickedFileName != null;
    if (text.isEmpty && !hasFile) return;
    setState(() => _saving = true);
    try {
      if (hasFile) {
        final tipo =
            _pickedTipo ?? _determineTipo(_pickedMime, _pickedFileName!);
        await _service.guardarArchivoEnInbox(
          bytes: _pickedBytes!,
          fileName: _pickedFileName!,
          mimeType: _pickedMime ?? 'application/octet-stream',
          tipo: tipo,
          titulo: _titleController.text.trim().isEmpty
              ? _pickedFileName
              : _titleController.text.trim(),
          descripcion: _controller.text.trim().isNotEmpty
              ? _controller.text.trim()
              : null,
          tableroId: null,
        );
      } else {
        final isLink =
            text.startsWith('http://') || text.startsWith('https://');
        if (isLink) {
          await _service.guardarLinkEnInbox(
            url: text,
            titulo: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            descripcion: null,
          );
        } else {
          await _service.guardarTextoEnInbox(
            contenido: text,
            titulo: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
          );
        }
      }
      if (mounted) {
        await widget.onSaved();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enviado al Inbox')));
        _controller.clear();
        _titleController.clear();
        _pickedBytes = null;
        _pickedFileName = null;
        _pickedMime = null;
        _pickedTipo = null;
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _pickedBytes = file.bytes;
      _pickedFileName = file.name;
      _pickedMime = _guessMime(file.extension);
      _pickedTipo = _determineTipo(_pickedMime, _pickedFileName!);
    });
  }

  String _guessMime(String? ext) {
    if (ext == null) return 'text/plain';
    final e = ext.toLowerCase();
    switch (e) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'md':
        return 'text/markdown';
      case 'txt':
        return 'text/plain';
      default:
        return 'text/plain';
    }
  }

  String _determineTipo(String? mime, String name) {
    final m = mime ?? '';
    if (m.startsWith('image/')) return 'imagen';
    if (m.startsWith('audio/')) return 'audio';
    if (m.startsWith('video/')) return 'video';
    final lower = name.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp')) {
      return 'imagen';
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg'))
      return 'audio';
    if (lower.endsWith('.mp4') || lower.endsWith('.mov')) return 'video';
    return 'archivo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.foreground),
          onPressed: widget.onClose,
        ),
        title: const Text(
          'Añadir al Inbox',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Título (opcional)',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            ),
            const SizedBox(height: 6),
            _RoundedField(
              controller: _titleController,
              hint: 'Idea rápida, enlace, recordatorio...',
            ),
            const SizedBox(height: 16),
            const Text(
              'Contenido',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            ),
            const SizedBox(height: 6),
            _RoundedField(
              controller: _controller,
              hint: 'Pega un link o escribe una nota',
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saving ? null : _pickFile,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Adjuntar archivo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.foreground,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 12),
                if (_pickedFileName != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pickedFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _saving
                                ? null
                                : () {
                                    setState(() {
                                      _pickedBytes = null;
                                      _pickedFileName = null;
                                      _pickedMime = null;
                                    });
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_pickedBytes != null && _pickedTipo == 'imagen') ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Si el contenido empieza por http(s) se guardará como link; en otro caso como nota de texto.',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        backgroundColor: AppColors.primary,
        label: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Enviar al Inbox'),
        icon: _saving
            ? null
            : const Icon(Icons.inbox_outlined, color: Colors.white),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _RoundedField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.foreground),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.mutedForeground),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
