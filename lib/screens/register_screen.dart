import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'bio_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const RegisterScreen({super.key, required this.onLoginSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = SupabaseService();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscureConfirm = true;
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
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      setState(() => _error = 'Rellena todos los campos');
      return;
    }

    if (password != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.signUp(
        email: email,
        password: password,
        fullName: name,
        username: username,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BioScreen(onLoginSuccess: widget.onLoginSuccess),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString().split(']').last.trim()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? obscure,
    VoidCallback? onToggleObscure,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
          child: TextField(
            controller: controller,
            obscureText: obscure ?? false,
            keyboardType: type,
            style: const TextStyle(color: AppColors.foreground, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.mutedForeground),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.mutedForeground,
                size: 18,
              ),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: onToggleObscure,
                      child: Icon(
                        obscure!
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.mutedForeground,
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
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
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.foreground,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Únete para organizar tu mundo',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  label: 'NOMBRE COMPLETO',
                  controller: _nameCtrl,
                  hint: 'Tu nombre',
                  icon: Icons.person_outline,
                ),

                _buildTextField(
                  label: 'NOMBRE DE USUARIO',
                  controller: _usernameCtrl,
                  hint: '@tu_usuario',
                  icon: Icons.alternate_email,
                ),

                _buildTextField(
                  label: 'EMAIL',
                  controller: _emailCtrl,
                  hint: 'tu@email.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),

                _buildTextField(
                  label: 'CONTRASEÑA',
                  controller: _passwordCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                ),

                _buildTextField(
                  label: 'CONFIRMAR CONTRASEÑA',
                  controller: _confirmCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscure: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
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
                ],

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
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
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
