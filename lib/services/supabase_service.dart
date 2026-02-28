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

    // Módificado: el trigger de la base de datos (handle_new_user)
    // crea una fila por defecto en "perfiles", por lo que aquí hacemos upsert
    // para rellenar los datos extra sin saltar error de duplicado.
    await upsertPerfil(
      userId: user.id,
      username: username,
      nombreCompleto: fullName,
    );
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

  /// Perfil público por username (o id si solo tienes eso).
  Future<Map<String, dynamic>?> getPerfilPublico({
    String? userId,
    String? username,
  }) async {
    assert(userId != null || username != null, 'Debes pasar userId o username');
    var query = _supabase.from('perfiles').select();
    if (userId != null) {
      query = query.eq('id', userId);
    } else if (username != null) {
      query = query.eq('username', username);
    }
    return await query.maybeSingle();
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

  /// Tableros públicos de otro usuario
  Future<List<Map<String, dynamic>>> getTablerosPublicos(String userId) async {
    final res = await _supabase
        .from('tableros')
        .select()
        .eq('user_id', userId)
        .eq('is_public', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Items públicos de un usuario (opcionalmente filtrados por tablero)
  Future<List<Map<String, dynamic>>> getItemsPublicos({
    required String userId,
    String? tableroId,
  }) async {
    var query = _supabase
        .from('items')
        .select()
        .eq('user_id', userId)
        .eq('is_public', true);
    if (tableroId != null) {
      query = query.eq('tablero_id', tableroId);
    }
    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Copia un item público de otro usuario a tu inbox (tablero null) para editarlo.
  Future<Map<String, dynamic>> copiarItemPublicoAInbox(String itemId) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    // Obtener item público
    final origen = await _supabase
        .from('items')
        .select()
        .eq('id', itemId)
        .eq('is_public', true)
        .maybeSingle();
    if (origen == null) {
      throw Exception('Item no encontrado o no es público');
    }

    final payload = {
      'user_id': user.id,
      'tablero_id': null,
      'titulo': origen['titulo'],
      'contenido': origen['contenido'],
      'tipo': origen['tipo'],
      'estado': 'inbox',
      'tags': origen['tags'],
      'is_public': false,
      'raw_data': {
        'source_user_id': origen['user_id'],
        'source_item_id': origen['id'],
        'copied_at': DateTime.now().toIso8601String(),
        'original_raw_data': origen['raw_data'],
      },
    };

    final res = await _supabase.from('items').insert(payload).select().single();
    return res;
  }

  // ─── SUGERENCIAS ─────────────────────────────────
  /// Sugiere un item existente tuyo a un tablero de otro usuario.
  Future<Map<String, dynamic>> sugerirItemExistente({
    required String itemId,
    required String targetUserId,
    required String targetTableroId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    final item = await _supabase
        .from('items')
        .select()
        .eq('id', itemId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (item == null) throw Exception('Item no encontrado o no es tuyo');

    final payload = {
      'autor_id': user.id,
      'target_user_id': targetUserId,
      'target_tablero_id': targetTableroId,
      'titulo': item['titulo'],
      'contenido': item['contenido'],
      'tipo': item['tipo'],
      'raw_data': item['raw_data'],
    };

    final res = await _supabase
        .from('sugerencias')
        .insert(payload)
        .select()
        .single();
    return res;
  }

  // ─── CARTAS DE PROXIMIDAD ───────────────────────
  /// Envía una carta de texto. Si [targetUserId] es null, va para cercanos en general.
  Future<Map<String, dynamic>> enviarCarta({
    required String contenido,
    String? targetUserId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    final payload = {
      'autor_id': user.id,
      'contenido': contenido,
      'alcance': targetUserId == null ? 'cercanos' : 'directa',
      'target_user_id': targetUserId,
    };
    final res = await _supabase
        .from('cartas')
        .insert(payload)
        .select()
        .single();
    return res;
  }

  /// Obtiene cartas visibles para el usuario actual, ordenadas:
  /// 1) directas primero, 2) cercanos, 3) más recientes.
  /// Puedes pasar [nearbyUserIds] para priorizar/filtrar proximidad si ya la calculas.
  Future<List<Map<String, dynamic>>> getCartas({
    List<String>? nearbyUserIds,
    bool soloDirectas = false,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    // Base: cartas directas a mí o broadcast (alcance=cercanos) no borradas
    var query = _supabase
        .from('cartas')
        .select()
        .or(
          'target_user_id.eq.${user.id},and(target_user_id.is.null,alcance.eq.cercanos)',
        )
        .order('created_at', ascending: false);

    final cartas = List<Map<String, dynamic>>.from(await query);

    // Filtrar las marcadas como borradas
    final borradasRes = await _supabase
        .from('cartas_borradas')
        .select('carta_id')
        .eq('user_id', user.id);
    final borradasIds = borradasRes
        .map<String>((e) => e['carta_id'] as String)
        .toSet();

    final filtered = cartas
        .where((c) => !borradasIds.contains(c['id']))
        .toList();

    // Ordenar: directas > cercanos; dentro de cercanos priorizar autores cercanos si se pasa nearbyUserIds; luego fecha desc
    final nearbySet = nearbyUserIds != null ? nearbyUserIds.toSet() : null;
    filtered.sort((a, b) {
      int score(Map<String, dynamic> c) {
        final isDirect = c['target_user_id'] != null;
        final autor = c['autor_id'] as String?;
        final isNear =
            nearbySet != null && autor != null && nearbySet.contains(autor);
        final ts =
            DateTime.tryParse(c['created_at'] ?? '')?.millisecondsSinceEpoch ??
            0;
        return (isDirect ? 1000000000 : 0) + (isNear ? 1000000 : 0) + ts;
      }

      return score(b).compareTo(score(a));
    });

    if (soloDirectas) {
      return filtered.where((c) => c['target_user_id'] != null).toList();
    }
    return filtered;
  }

  /// Marca una carta como borrada para el receptor (no se elimina globalmente).
  Future<void> ocultarCartaParaMi(String cartaId) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    await _supabase.from('cartas_borradas').upsert({
      'user_id': user.id,
      'carta_id': cartaId,
    });
  }

  /// Sugiere un item nuevo “ad-hoc” (no existe en tus tableros).
  Future<Map<String, dynamic>> sugerirItemNuevo({
    required String targetUserId,
    required String targetTableroId,
    required String titulo,
    required String contenido,
    required String tipo, // texto | link | imagen | audio | video | archivo
    Map<String, dynamic>? rawData,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    final payload = {
      'autor_id': user.id,
      'target_user_id': targetUserId,
      'target_tablero_id': targetTableroId,
      'titulo': titulo,
      'contenido': contenido,
      'tipo': tipo,
      if (rawData != null) 'raw_data': rawData,
    };
    final res = await _supabase
        .from('sugerencias')
        .insert(payload)
        .select()
        .single();
    return res;
  }

  /// Lista sugerencias recibidas para un tablero del usuario actual.
  Future<List<Map<String, dynamic>>> getSugerenciasTablero(
    String tableroId,
  ) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    final res = await _supabase
        .from('sugerencias')
        .select()
        .eq('target_user_id', user.id)
        .eq('target_tablero_id', tableroId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Aceptar o rechazar una sugerencia. Si se acepta, se crea el item en el tablero destino.
  Future<void> resolverSugerencia({
    required String sugerenciaId,
    required bool aceptar,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    final sug = await _supabase
        .from('sugerencias')
        .select()
        .eq('id', sugerenciaId)
        .eq('target_user_id', user.id)
        .maybeSingle();
    if (sug == null) throw Exception('Sugerencia no encontrada');

    if (aceptar) {
      await _supabase.from('items').insert({
        'user_id': user.id,
        'tablero_id': sug['target_tablero_id'],
        'titulo': sug['titulo'],
        'contenido': sug['contenido'],
        'tipo': sug['tipo'],
        'estado': 'organizado',
        'is_public': false,
        'raw_data': {
          'from_suggestion_id': sugerenciaId,
          'autor_id': sug['autor_id'],
          'copied_at': DateTime.now().toIso8601String(),
          'original_raw_data': sug['raw_data'],
        },
      });
      await _supabase
          .from('sugerencias')
          .update({
            'estado': 'aceptada',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sugerenciaId);
    } else {
      await _supabase
          .from('sugerencias')
          .update({
            'estado': 'rechazada',
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sugerenciaId);
    }
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

  /// Sube una imagen de portada y devuelve una URL firmada.
  Future<String> subirImagenPortada({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    final safeName = fileName.replaceAll(' ', '-');
    final randomSuffix = Random().nextInt(1 << 32);
    final objectPath =
        'board-covers/${DateTime.now().millisecondsSinceEpoch}-$randomSuffix-$safeName';

    await _supabase.storage
        .from('inbox-uploads')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    return await _supabase.storage
        .from('inbox-uploads')
        .createSignedUrl(objectPath, 60 * 60 * 24 * 7);
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
    await _supabase
        .from('items')
        .update({
          'tablero_id': nuevoTableroId,
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  Future<void> eliminarItem(String itemId) async {
    await _supabase.from('items').delete().eq('id', itemId);
  }

  Future<void> cambiarVisibilidadItem({
    required String itemId,
    required bool isPublic,
  }) async {
    await _supabase
        .from('items')
        .update({
          'is_public': isPublic,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
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
    await _supabase
        .from('tableros')
        .update({
          'parent_id': nuevoParentId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tableroId);
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
  /// Register or update an encounter with another user.
  Future<void> registrarEncuentro(String otherUserId) async {
    final user = currentUser;
    if (user == null) return;

    await _supabase.from('encuentros').upsert({
      'user_id': user.id,
      'usuario_encontrado_id': otherUserId,
      'visto_en': DateTime.now().toIso8601String(),
    }, onConflict: 'encuentros_unique_users');
  }

  /// Get all encounters for the current user, with profile info.
  Future<List<Map<String, dynamic>>> getEncuentros(String userId) async {
    final res = await _supabase
        .from('encuentros')
        .select('*, usuario_encontrado:perfiles!usuario_encontrado_id(*)')
        .eq('user_id', userId)
        .order('visto_en', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Remove an encounter from the 'Walked' list
  Future<void> eliminarEncuentro(String otherUserId) async {
    final user = currentUser;
    if (user == null) return;
    await _supabase
        .from('encuentros')
        .delete()
        .eq('user_id', user.id)
        .eq('usuario_encontrado_id', otherUserId);
  }
}
