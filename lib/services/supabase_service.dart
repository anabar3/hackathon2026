// lib/services/supabase_service.dart
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ─── AUTH ────────────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null) throw Exception('No se pudo crear el usuario');

    await _supabase.from('perfiles').insert({
      'id': user.id,
      'username': username,
      'nombre_completo': fullName,
      'bio': null,
      'avatar_url': null,
      'intereses': <String>[],
    });
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
    String? parentId,
  }) async {
    // Asegura que exista el perfil para respetar la FK perfiles(id)
    await _ensurePerfil();

    await _supabase.from('tableros').insert({
      'user_id': userId,
      'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (imagenPortada != null) 'imagen_portada': imagenPortada,
      'is_public': isPublic,
      'parent_id': parentId,
    });
  }

  // ─── ITEMS (INBOX) ──────────────────────────────
  /// Guarda texto libre en el inbox (sin tablero por defecto).
  Future<Map<String, dynamic>> guardarTextoEnInbox({
    required String contenido,
    String? titulo,
    String? tableroId,
    List<String>? tags,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    await _ensurePerfil();

    final payload = {
      'user_id': user.id,
      'tablero_id': tableroId,
      'titulo': titulo,
      'contenido': contenido,
      'tipo': 'texto',
      'estado': 'inbox',
      if (tags != null) 'tags': tags,
      'raw_data': contenido,
    };

    final res = await _supabase.from('items').insert(payload).select().single();
    return res;
  }

  /// Guarda un enlace. Incluye metadatos básicos (dominio, og_image, etc.) si ya los tienes.
  Future<Map<String, dynamic>> guardarLinkEnInbox({
    required String url,
    String? titulo,
    String? tableroId,
    List<String>? tags,
    Map<String, dynamic>? linkMeta,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    await _ensurePerfil();

    final payload = {
      'user_id': user.id,
      'tablero_id': tableroId,
      'titulo': titulo,
      'contenido': url,
      'tipo': 'link',
      'estado': 'inbox',
      if (tags != null) 'tags': tags,
      if (linkMeta != null) 'raw_data': linkMeta,
    };

    final res = await _supabase.from('items').insert(payload).select().single();
    return res;
  }

  /// Guarda una foto, nota de voz o archivo subiendo primero a Storage.
  /// [tipo] debe ser 'imagen', 'audio' o 'archivo' para que coincida con el ENUM en la BD.
  Future<Map<String, dynamic>> guardarArchivoEnInbox({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String tipo,
    String? titulo,
    String? tableroId,
    List<String>? tags,
    Duration? duracion,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    await _ensurePerfil();

    if (!['imagen', 'audio', 'archivo', 'video'].contains(tipo)) {
      throw Exception('Tipo inválido para archivo: $tipo');
    }

    // Para imágenes usamos un mock para ahorrar espacio en el bucket.
    String contenidoUrl;
    Map<String, dynamic> rawData;

    if (tipo == 'imagen') {
      contenidoUrl = _mockImageUrl();
      rawData = {
        'mocked': true,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': bytes.lengthInBytes,
      };
    } else {
      final uploadInfo = await _subirAStorageInbox(
        bytes: bytes,
        userId: user.id,
        fileName: fileName,
        mimeType: mimeType,
      );
      contenidoUrl = uploadInfo['signedUrl']!;
      rawData = {
        'storage_path': uploadInfo['path'],
        'mime_type': mimeType,
        'file_name': fileName,
        'size_bytes': bytes.lengthInBytes,
        if (duracion != null) 'duration_ms': duracion.inMilliseconds,
      };
    }

    final payload = {
      'user_id': user.id,
      'tablero_id': tableroId,
      'titulo': titulo ?? fileName,
      'contenido': contenidoUrl,
      'tipo': tipo,
      'estado': 'inbox',
      if (tags != null) 'tags': tags,
      'raw_data': rawData,
    };

    final res = await _supabase.from('items').insert(payload).select().single();
    return res;
  }

  /// Garantiza que exista la fila en perfiles para el usuario actual.
  Future<void> _ensurePerfil() async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    final existing = await _supabase
        .from('perfiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    final base = (user.email ?? 'usuario').split('@').first;
    final username = '${base}_${user.id.substring(0, 6)}';
    await _supabase.from('perfiles').insert({
      'id': user.id,
      'username': username,
      'nombre_completo': user.email ?? 'Nuevo usuario',
      'bio': null,
      'avatar_url': null,
      'intereses': <String>[],
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

  Future<List<Map<String, dynamic>>> getItemsPorTablero({
    required String userId,
    required String tableroId,
  }) async {
    final res = await _supabase
        .from('items')
        .select()
        .eq('user_id', userId)
        .eq('tablero_id', tableroId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> actualizarItem({
    required String itemId,
    String? titulo,
    String? contenido,
    List<String>? tags,
    String? tableroId,
    String? estado, // inbox | organizado | archivado
    String? tipo, // texto | link | imagen | audio | video | archivo
    bool? isPublic,
    Map<String, dynamic>? rawData,
  }) async {
    final updates = <String, dynamic>{
      'id': itemId,
      if (titulo != null) 'titulo': titulo,
      if (contenido != null) 'contenido': contenido,
      if (tags != null) 'tags': tags,
      if (tableroId != null) 'tablero_id': tableroId,
      if (estado != null) 'estado': estado,
      if (tipo != null) 'tipo': tipo,
      if (isPublic != null) 'is_public': isPublic,
      if (rawData != null) 'raw_data': rawData,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('items').update(updates).eq('id', itemId);
  }

  Future<void> moverItem({
    required String itemId,
    String? nuevoTableroId,
    String nuevoEstado = 'organizado',
  }) async {
    await _supabase.from('items').update({
      'tablero_id': nuevoTableroId,
      'estado': nuevoEstado,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  Future<void> eliminarItem(String itemId) async {
    await _supabase.from('items').delete().eq('id', itemId);
  }

  Future<void> cambiarVisibilidadItem({
    required String itemId,
    required bool isPublic,
  }) async {
    await _supabase.from('items').update({
      'is_public': isPublic,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  // ─── TABLEROS ANIDADOS ──────────────────────────
  Future<List<Map<String, dynamic>>> getTablerosHijos({
    required String userId,
    String? parentId,
  }) async {
    var query = _supabase.from('tableros').select().eq('user_id', userId);
    if (parentId == null) {
      query = query.isFilter('parent_id', null);
    } else {
      query = query.eq('parent_id', parentId);
    }
    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> actualizarTablero({
    required String tableroId,
    String? titulo,
    String? descripcion,
    String? imagenPortada,
    bool? isPublic,
    String? parentId,
  }) async {
    final updates = <String, dynamic>{
      'id': tableroId,
      if (titulo != null) 'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (imagenPortada != null) 'imagen_portada': imagenPortada,
      if (isPublic != null) 'is_public': isPublic,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (parentId != null) {
      updates['parent_id'] = parentId;
    } else if (parentId == null && updates.containsKey('parent_id')) {
      // do nothing, only set if provided; leaving null means no change
    }
    await _supabase.from('tableros').update(updates).eq('id', tableroId);
  }

  Future<void> moverTablero({
    required String tableroId,
    String? nuevoParentId,
  }) async {
    await _supabase.from('tableros').update({
      'parent_id': nuevoParentId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tableroId);
  }

  Future<void> eliminarTablero(String tableroId) async {
    await _supabase.from('tableros').delete().eq('id', tableroId);
  }

  // ─── STORAGE HELPERS ────────────────────────────
  Future<Map<String, String>> _subirAStorageInbox({
    required Uint8List bytes,
    required String userId,
    required String fileName,
    required String mimeType,
  }) async {
    // Prefijo por usuario para aplicar políticas de RLS en Storage
    final safeName = fileName.replaceAll(' ', '-');
    final randomSuffix = Random().nextInt(1 << 32);
    final objectPath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}-$randomSuffix-$safeName';

    await _supabase.storage
        .from('inbox-uploads')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    // URL firmada por 7 días. El front puede renovarla o usar getPublicUrl si el bucket se marca como público.
    final signedUrl = await _supabase.storage
        .from('inbox-uploads')
        .createSignedUrl(objectPath, 60 * 60 * 24 * 7);

    return {'path': objectPath, 'signedUrl': signedUrl};
  }

  // Imagenes mock para ahorrar espacio
  String _mockImageUrl() {
    const urls = [
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80',
      'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
      'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800&q=80',
    ];
    return urls[Random().nextInt(urls.length)];
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

  // ─── AI SUGGESTIONS ─────────────────────────────
  Future<void> aplicarSugerencia({
    required String itemId,
    required String tableroId,
  }) async {
    await _supabase
        .from('items')
        .update({'tablero_id': tableroId, 'estado': 'organizado'})
        .eq('id', itemId);
  }

  Future<String> crearTableroConRetornoId({
    required String userId,
    required String titulo,
    String? descripcion,
  }) async {
    final res = await _supabase
        .from('tableros')
        .insert({
          'user_id': userId,
          'titulo': titulo,
          if (descripcion != null) 'descripcion': descripcion,
          'is_public': false,
        })
        .select('id')
        .single();

    return res['id'] as String;
  }
}
