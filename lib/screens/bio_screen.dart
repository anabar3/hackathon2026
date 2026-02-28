import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class BioScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const BioScreen({super.key, required this.onLoginSuccess});

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen>
    with SingleTickerProviderStateMixin {
  final _bioCtrl = TextEditingController();
  final _service = SupabaseService();
  bool _loading = false;
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitBio() async {
    final bio = _bioCtrl.text.trim();
    if (bio.isEmpty) {
      // Just skip if empty
      widget.onLoginSuccess();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _service.currentUser;
      if (user != null) {
        await _service.upsertPerfil(userId: user.id, bio: bio);
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onLoginSuccess();
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString().split(']').last.trim()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skipBiO() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(51),
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Tu Perfil',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Cuéntanos un poco sobre ti (Opcional)',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                const Text(
                  'BIOGRAFÍA',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  height: 120,
                  child: TextField(
                    controller: _bioCtrl,
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Añade una breve descripción...',
                      hintStyle: TextStyle(color: AppColors.mutedForeground),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFC75050),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFC75050),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitBio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withAlpha(128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: _loading ? null : _skipBiO,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mutedForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Saltar por ahora',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
