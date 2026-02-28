import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/animated_entry.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = SupabaseService();
  final _usernameCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nombreCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPerfil() async {
    final user = _service.currentUser;
    if (user == null) return;
    try {
      final perfil = await _service.getPerfil(user.id);
      if (perfil != null) {
        _usernameCtrl.text = perfil['username'] ?? '';
        _nombreCtrl.text = perfil['nombre_completo'] ?? '';
        _bioCtrl.text = perfil['bio'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guardar() async {
    final user = _service.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await _service.upsertPerfil(
        userId: user.id,
        username: _usernameCtrl.text.trim().isNotEmpty
            ? _usernameCtrl.text.trim()
            : null,
        nombreCompleto: _nombreCtrl.text.trim().isNotEmpty
            ? _nombreCtrl.text.trim()
            : null,
        bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      );
      await _loadPerfil();

      setState(() {
        _message = '✓ Perfil guardado';
      });
    } catch (e) {
      setState(
        () => _message = 'Error: ${e.toString().split(']').last.trim()}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final user = _service.currentUser;
    final email = user?.email ?? '';

    return SafeArea(
      child: AnimatedEntry(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.border,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.foreground,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Card with Editable Fields
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _nombreCtrl.text.isNotEmpty
                                  ? _nombreCtrl.text[0].toUpperCase()
                                  : (email.isNotEmpty
                                        ? email[0].toUpperCase()
                                        : '?'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildField(
                      'NOMBRE COMPLETO',
                      _nombreCtrl,
                      'Nombre completo',
                    ),
                    const SizedBox(height: 16),
                    _buildField('USERNAME', _usernameCtrl, 'Username'),
                    const SizedBox(height: 16),
                    _buildField(
                      'BIO',
                      _bioCtrl,
                      'Algo sobre ti...',
                      maxLines: 3,
                    ),

                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _message!.startsWith('✓')
                              ? AppColors.primary.withAlpha(26)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _message!.startsWith('✓')
                                ? AppColors.primary.withAlpha(51)
                                : const Color(0xFFFCA5A5),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.startsWith('✓')
                                ? AppColors.primary
                                : const Color(0xFFC75050),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withAlpha(
                            128,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Logout
              Center(
                child: GestureDetector(
                  onTap: widget.onLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFFCA5A5),
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: Color(0xFFC75050), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: Color(0xFFC75050),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: const [
              BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
