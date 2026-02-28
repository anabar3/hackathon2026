import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class CardsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const CardsScreen({super.key, required this.onBack});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _service = SupabaseService();
  bool _loading = true;
  List<Map<String, dynamic>> _cartas = [];
  final _textController = TextEditingController();
  final _targetController = TextEditingController();
  bool _isDirect = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _service.getCartas();
      setState(() => _cartas = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ocultar(String id) async {
    await _service.ocultarCartaParaMi(id);
    await _load();
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
          'Cartas',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline, color: AppColors.primary),
            onPressed: _openComposer,
          )
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _cartas.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No hay cartas.',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemBuilder: (context, i) {
                      final c = _cartas[i];
                      final isDirect = c['target_user_id'] != null;
                      final ts = DateTime.tryParse(c['created_at'] ?? '');
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          title: Text(
                            c['contenido'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${isDirect ? "Directa" : "Cercanos"} · ${_fmt(ts)} · de ${c['autor_id'] ?? "?"}',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.hide_source,
                                color: AppColors.mutedForeground),
                            onPressed: () => _ocultar(c['id']),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _cartas.length,
                  ),
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<void> _openComposer() async {
    _textController.clear();
    _targetController.clear();
    _isDirect = false;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enviar carta',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: AppColors.mutedForeground),
                        onPressed: () => Navigator.pop(context, false),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _isDirect,
                    onChanged: (v) => setSheetState(() {
                      _isDirect = v;
                    }),
                    activeColor: AppColors.primary,
                    title: const Text(
                      'Enviar directo a un usuario',
                      style: TextStyle(color: AppColors.foreground),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isDirect)
                    TextField(
                      controller: _targetController,
                      decoration: const InputDecoration(
                        labelText: 'User ID destino',
                        hintText: 'uuid del destinatario',
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_textController.text.trim().isEmpty) return;
                        await _service.enviarCarta(
                          contenido: _textController.text.trim(),
                          targetUserId:
                              _isDirect ? _targetController.text.trim() : null,
                        );
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (sent == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carta enviada')),
      );
    }
  }
}
