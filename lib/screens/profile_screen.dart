import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
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
  String? _avatarUrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
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
        _avatarUrl = perfil['avatar_url'];
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
      setState(() => _message = '✓ Perfil guardado');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _message != null && _message!.startsWith('✓')) {
          setState(() => _message = null);
        }
      });
    } catch (e) {
      setState(
        () => _message = 'Error: ${e.toString().split(']').last.trim()}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = _service.currentUser;
    if (user == null) return;

    setState(() {
      _uploadingAvatar = true;
      _message = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _uploadingAvatar = false);
        return;
      }
      final file = result.files.first;
      if (file.bytes == null) {
        setState(() {
          _uploadingAvatar = false;
          _message = 'No se pudo leer la imagen seleccionada';
        });
        return;
      }

      final ext = (file.extension ?? '').toLowerCase();
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final publicUrl = await _service.uploadAvatar(
        bytes: file.bytes!,
        fileName: file.name,
        mimeType: mimeType,
      );

      await _service.upsertPerfil(
        userId: user.id,
        avatarUrl: publicUrl,
      );

      // refresca datos locales
      await _loadPerfil();
      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          _message = '✓ Foto de perfil actualizada';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error subiendo la imagen: ${e.toString().split(']').last}';
        });
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
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
    final displayName = _nombreCtrl.text.isNotEmpty
        ? _nombreCtrl.text
        : (email.isNotEmpty ? email.split('@').first : '?');
    final displayUsername = _usernameCtrl.text.isNotEmpty
        ? '@${_usernameCtrl.text}'
        : '';
    final initial = _nombreCtrl.text.isNotEmpty
        ? _nombreCtrl.text[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return SafeArea(
      child: AnimatedEntry(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title — left aligned like reference ──
              // ── Title & Logout ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Mi Perfil',
                    style: GoogleFonts.dmSans(
                      color: AppColors.foreground,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onLogout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFDC2626),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Salir',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Profile Card — matches reference layout ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar row — avatar left, edit button right (like reference)
                    Row(
                      children: [
                        // Avatar with thin border
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                            color: AppColors.primary.withAlpha(18),
                            image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                              ? Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.primary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const Spacer(),
                        // Edit Image button (like reference)
                        GestureDetector(
                          onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: _uploadingAvatar
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Text(
                                    'Editar foto',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.foreground,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Full name — large and bold, left aligned (like reference)
                    Text(
                      displayName,
                      style: GoogleFonts.dmSans(
                        color: AppColors.foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Username + bio row
                    if (displayUsername.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayUsername,
                            style: GoogleFonts.dmSans(
                              color: AppColors.mutedForeground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_bioCtrl.text.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Container(
                                width: 1,
                                height: 14,
                                color: AppColors.border,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _bioCtrl.text,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.mutedForeground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Edit fields section ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      'NOMBRE COMPLETO',
                      _nombreCtrl,
                      'Tu nombre completo',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'USERNAME',
                      _usernameCtrl,
                      'Tu nombre de usuario',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'BIO',
                      _bioCtrl,
                      'Algo sobre ti...',
                      maxLines: 3,
                    ),

                    // Status message
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _message!.startsWith('✓')
                              ? AppColors.primary.withAlpha(20)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _message!.startsWith('✓')
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: _message!.startsWith('✓')
                                  ? AppColors.primary
                                  : const Color(0xFFC75050),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _message!.startsWith('✓')
                                    ? 'Perfil guardado'
                                    : _message!,
                                style: GoogleFonts.dmSans(
                                  color: _message!.startsWith('✓')
                                      ? AppColors.primary
                                      : const Color(0xFFC75050),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withAlpha(
                            128,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Guardar Cambios',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Nothing below except padding
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
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.mutedForeground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: AppColors.mutedForeground.withAlpha(150),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
