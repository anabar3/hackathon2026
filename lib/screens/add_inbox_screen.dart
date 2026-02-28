import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class AddInboxScreen extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function() onSaved;
  const AddInboxScreen({super.key, required this.onClose, required this.onSaved});

  @override
  State<AddInboxScreen> createState() => _AddInboxScreenState();
}

class _AddInboxScreenState extends State<AddInboxScreen> {
  final _service = SupabaseService();
  final _controller = TextEditingController();
  final _titleController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final isLink = text.startsWith('http://') || text.startsWith('https://');
      if (isLink) {
        await _service.guardarLinkEnInbox(
          url: text,
          titulo: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
        );
      } else {
        await _service.guardarTextoEnInbox(
          contenido: text,
          titulo: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
        );
      }
      if (mounted) {
        await widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviado al Inbox')),
        );
        _controller.clear();
        _titleController.clear();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Título (opcional)',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            _RoundedField(
              controller: _titleController,
              hint: 'Idea rápida, enlace, recordatorio...',
            ),
            const SizedBox(height: 16),
            const Text(
              'Contenido',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            _RoundedField(
              controller: _controller,
              hint: 'Pega un link o escribe una nota',
              maxLines: 6,
            ),
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
