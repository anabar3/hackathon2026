// lib/services/supabase_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'groq_service.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ─── PROFILE CACHE (in-memory, survives screen rebuilds) ──
  static String? cachedUserName;
  static String? cachedUserAvatar;

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
    // Cache immediately after signup
    cachedUserName = fullName;
  }

  Future<void> signOut() async {
    cachedUserName = null;
    cachedUserAvatar = null;
    await _supabase.auth.signOut();
  }

  // ─── PERFIL ─────────────────────────────────────
  Future<Map<String, dynamic>?> getPerfil(String userId) async {
    final res = await _supabase
        .from('perfiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    // Update cache
    if (res != null) {
      cachedUserName = res['nombre_completo'] ?? res['username'];
      cachedUserAvatar = res['avatar_url'];
    }
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

  /// Tableros públicos de otro usuario (con conteo de items)
  Future<List<Map<String, dynamic>>> getTablerosPublicos(String userId) async {
    final res = await _supabase
        .from('tableros')
        .select('*, items(count)')
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

  /// Todos los items de un tablero público (los items heredan visibilidad del tablero)
  Future<List<Map<String, dynamic>>> getItemsDeTableroPublico({
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

  /// Copia un item de un tablero público de otro usuario a tu inbox.
  Future<Map<String, dynamic>> copiarItemPublicoAInbox(String itemId) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');

    // Obtener item (RLS ya garantiza que solo se acceden items visibles)
    final origen = await _supabase
        .from('items')
        .select()
        .eq('id', itemId)
        .maybeSingle();
    if (origen == null) {
      throw Exception('Item no encontrado o no accesible');
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
      'metadatos': {
        'source_user_id': origen['user_id'],
        'source_item_id': origen['id'],
        'copied_at': DateTime.now().toIso8601String(),
        'original_raw_data': origen['metadatos'],
      },
    };

    return await _insertItemConFallback(payload);
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
      'raw_data': item['metadatos'],
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
        'metadatos': {
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
    required String userId,
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    // Reutilizamos la misma política de Storage que ya permite uploads bajo el prefijo userId/.
    final upload = await _subirAStorageInbox(
      bytes: bytes,
      userId: userId,
      fileName: fileName,
      mimeType: mimeType,
    );
    return upload['signedUrl']!;
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
      'metadatos': contenido,
    };

    return await _insertItemConFallback(payload);
  }

  /// Guarda un enlace. Incluye metadatos básicos (dominio, og_image, etc.) si ya los tienes.
  Future<Map<String, dynamic>> guardarLinkEnInbox({
    required String url,
    String? titulo,
    String? descripcion,
    String? tableroId,
    List<String>? tags,
    Map<String, dynamic>? linkMeta,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero');
    await _ensurePerfil();

    // Fetch link content for AI parsing
    final groq = GroqService();
    final scrapedText = await groq.fetchLinkContent(url);

    final rawData = Map<String, dynamic>.from(linkMeta ?? {});
    if (scrapedText != null) {
      rawData['scraped_text'] = scrapedText;
    }

    final payload = {
      'user_id': user.id,
      'tablero_id': tableroId,
      'titulo': titulo,
      'contenido': url,
      'tipo': 'link',
      'estado': 'inbox',
      if (tags != null) 'tags': tags,
      'metadatos': rawData,
    };

    return await _insertItemConFallback(payload);
  }

  /// Guarda una foto, nota de voz o archivo subiendo primero a Storage.
  /// [tipo] debe ser 'imagen', 'audio' o 'archivo' para que coincida con el ENUM en la BD.
  Future<Map<String, dynamic>> guardarArchivoEnInbox({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String tipo,
    String? titulo,
    String? descripcion,
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

    // Para imágenes y otros archivos subimos a Storage.
    String contenidoUrl;
    Map<String, dynamic> rawData;

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

    if (tipo == 'audio') {
      try {
        final groq = GroqService();
        final transcription = await groq.transcribeAudio(bytes, fileName);
        if (transcription.isNotEmpty) {
          rawData['transcription'] = transcription;
        }
      } catch (e) {
        debugPrint('Error transcribing audio: $e');
      }
    } else if (tipo == 'archivo') {
      try {
        if (mimeType == 'application/pdf') {
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          final String text = PdfTextExtractor(document).extractText();
          document.dispose();
          if (text.isNotEmpty) {
            // PostgreSQL db does not support '\u0000' character storage natively in text fields without specialized encoding
            rawData['extracted_text'] = text.replaceAll('\u0000', '');
          }
        } else if (mimeType == 'text/markdown' || mimeType == 'text/plain') {
          final String text = utf8.decode(bytes, allowMalformed: true);
          if (text.isNotEmpty) {
            rawData['extracted_text'] = text;
          }
        }
      } catch (e) {
        debugPrint('Error extracting document text: $e');
      }
    }

    final payload = {
      'user_id': user.id,
      'tablero_id': tableroId,
      'titulo': titulo ?? fileName,
      'contenido': contenidoUrl,
      'tipo': tipo,
      'estado': 'inbox',
      if (tags != null) 'tags': tags,
      'metadatos': rawData,
    };

    return await _insertItemConFallback(payload);
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
      if (rawData != null) 'metadatos': rawData,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _updateItemConFallback(updates, itemId);
  }

  Future<void> moverItem({
    required String itemId,
    String? nuevoTableroId,
    String nuevoEstado = 'organizado',
  }) async {
    await _updateItemConFallback({
      'tablero_id': nuevoTableroId,
      'estado': nuevoEstado,
      'updated_at': DateTime.now().toIso8601String(),
    }, itemId);
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

  // ─── INSERT/UPDATE HELPERS (graceful fallback si falta raw_data / metadatos) ────────────
  Future<Map<String, dynamic>> _insertItemConFallback(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _supabase.from('items').insert(payload).select().single();
    } on PostgrestException catch (e) {
      if ((e.message ?? '').contains('metadatos')) {
        payload.remove('metadatos');
        return await _supabase.from('items').insert(payload).select().single();
      }
      rethrow;
    }
  }

  Future<void> _updateItemConFallback(
    Map<String, dynamic> updates,
    String itemId,
  ) async {
    try {
      await _supabase.from('items').update(updates).eq('id', itemId);
    } on PostgrestException catch (e) {
      if ((e.message ?? '').contains('metadatos')) {
        updates.remove('metadatos');
        await _supabase.from('items').update(updates).eq('id', itemId);
        return;
      }
      rethrow;
    }
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

  // ─── ENCUENTROS ─────────────────────────────────
  /// Register or update an encounter with another user.
  Future<void> registrarEncuentro(String otherUserId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Try upsert with column-based conflict (user_id, usuario_encontrado_id)
      await _supabase.from('encuentros').upsert({
        'user_id': user.id,
        'usuario_encontrado_id': otherUserId,
        'visto_en': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,usuario_encontrado_id');
      print('[Supabase] Encounter recorded: ${user.id} -> $otherUserId');
    } catch (e) {
      // If upsert fails (e.g. no unique constraint), try plain insert
      print('[Supabase] Upsert failed ($e), trying insert...');
      try {
        await _supabase.from('encuentros').insert({
          'user_id': user.id,
          'usuario_encontrado_id': otherUserId,
          'visto_en': DateTime.now().toIso8601String(),
        });
        print('[Supabase] Encounter inserted via fallback');
      } catch (e2) {
        print('[Supabase] Fallback insert also failed: $e2');
      }
    }
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
