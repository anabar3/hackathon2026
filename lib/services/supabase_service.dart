// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ─── AUTH ────────────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signInOrSignUp(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      await _supabase.auth.signUp(email: email, password: password);
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── PERFIL ─────────────────────────────────────
  Future<Map<String, dynamic>?> getPerfil(String userId) async {
    final res = await _supabase
        .from('perfiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res;
  }

  Future<void> upsertPerfil({
    required String userId,
    String? username,
    String? nombreCompleto,
    String? bio,
    String? avatarUrl,
    List<String>? intereses,
  }) async {
    await _supabase.from('perfiles').upsert({
      'id': userId,
      if (username != null) 'username': username,
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (intereses != null) 'intereses': intereses,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
  }

  // ─── TABLEROS ───────────────────────────────────
  Future<List<Map<String, dynamic>>> getTableros(String userId) async {
    final res = await _supabase
        .from('tableros')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> crearTablero({
    required String userId,
    required String titulo,
    String? descripcion,
    String? imagenPortada,
    bool isPublic = false,
  }) async {
    await _supabase.from('tableros').insert({
      'user_id': userId,
      'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (imagenPortada != null) 'imagen_portada': imagenPortada,
      'is_public': isPublic,
    });
  }

  // ─── ITEMS (INBOX) ──────────────────────────────
  Future<void> enviarAlInbox(String texto) async {
    final user = currentUser;
    if (user == null) throw Exception("Debes iniciar sesión primero");

    await _supabase.from('items').insert({
      'user_id': user.id,
      'contenido': texto,
      'raw_data': texto,
      'tipo': 'texto',
      'estado': 'inbox',
    });
  }

  Future<List<Map<String, dynamic>>> getItems(String userId) async {
    final res = await _supabase
        .from('items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── ENCUENTROS ─────────────────────────────────
  Future<List<Map<String, dynamic>>> getEncuentros(String userId) async {
    final res = await _supabase
        .from('encuentros')
        .select('*, usuario_encontrado:perfiles!usuario_encontrado_id(*)')
        .eq('user_id', userId)
        .order('visto_en', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
