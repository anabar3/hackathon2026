-- ═══════════════════════════════════════════════════════
-- SEED DATA — Collect App (dev)
-- Auto-detecta el primer usuario registrado en auth.users
-- Solo se guardan REFERENCIAS (URLs) para imágenes, audio y video.
-- ═══════════════════════════════════════════════════════

DO $$
DECLARE
  uid UUID;
BEGIN
  -- Tomar el primer usuario registrado
  SELECT id INTO uid FROM auth.users ORDER BY created_at LIMIT 1;

  IF uid IS NULL THEN
    RAISE EXCEPTION 'No hay usuarios en auth.users. Regístrate primero en la app.';
  END IF;

  -- ── PERFIL ──
  INSERT INTO perfiles (id, username, nombre_completo, bio, avatar_url, intereses)
  VALUES (
    uid,
    'marcos',
    'Marcos Rivera',
    'Photographer & traveler. Collecting visual inspiration.',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
    ARRAY['travel', 'photography', 'architecture', 'food', 'music']
  )
  ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    nombre_completo = EXCLUDED.nombre_completo,
    bio = EXCLUDED.bio,
    avatar_url = EXCLUDED.avatar_url,
    intereses = EXCLUDED.intereses;

  -- ── TABLEROS ──
  INSERT INTO tableros (id, user_id, titulo, descripcion, imagen_portada, is_public) VALUES
  ('11111111-1111-1111-1111-111111111101', uid, 'Travel Inspo', 'Destinos soñados, arquitectura y paisajes del mundo', 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&q=80', true),
  ('11111111-1111-1111-1111-111111111102', uid, 'Recetas', 'Recetas favoritas y descubrimientos culinarios', 'https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=600&q=80', false),
  ('11111111-1111-1111-1111-111111111103', uid, 'Design Vault', 'UI patterns, tipografías y paletas de color', 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600&q=80', true),
  ('11111111-1111-1111-1111-111111111104', uid, 'Music Finds', 'Canciones, álbumes y playlists para recordar', 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600&q=80', true),
  ('11111111-1111-1111-1111-111111111105', uid, 'Reading List', 'Artículos, libros e hilos que quiero leer', NULL, false)
  ON CONFLICT (id) DO NOTHING;

  -- ── ITEMS ──
  INSERT INTO items (user_id, tablero_id, tipo, estado, titulo, contenido, raw_data, tags, is_public) VALUES

  -- ═══ TRAVEL INSPO ═══
  (uid, '11111111-1111-1111-1111-111111111101', 'imagen', 'organizado',
   'Santorini Blue Domes',
   'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800&q=80',
   '{"width":800,"height":600,"format":"jpg","source":"unsplash"}',
   ARRAY['greece', 'architecture', 'sunset', 'islands'], true),

  (uid, '11111111-1111-1111-1111-111111111101', 'imagen', 'organizado',
   'Kyoto Bamboo Grove',
   'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800&q=80',
   '{"width":800,"height":1200,"format":"jpg","source":"unsplash"}',
   ARRAY['japan', 'nature', 'zen', 'forest'], true),

  (uid, '11111111-1111-1111-1111-111111111101', 'video', 'organizado',
   'Northern Lights Timelapse',
   'https://cdn.pixabay.com/video/2021/09/07/88085-601379498_large.mp4',
   '{"duration":"00:32","resolution":"1080p","format":"mp4","source":"pixabay"}',
   ARRAY['aurora', 'iceland', 'timelapse', 'nature'], true),

  (uid, '11111111-1111-1111-1111-111111111101', 'link', 'organizado',
   'The 50 Best Places to Travel in 2026',
   'https://www.travelandleisure.com/best-places-to-go',
   '{"domain":"travelandleisure.com","og_image":"https://images.unsplash.com/photo-1488085061387-422e29b40080?w=400&q=80"}',
   ARRAY['travel', 'guide', 'destinations'], false),

  (uid, '11111111-1111-1111-1111-111111111101', 'texto', 'organizado',
   'Packing Checklist — Japan Trip',
   'Pasaporte, JR Pass, adaptador enchufe, cámara 35mm, powerbank 20k, paraguas plegable, zapatillas cómodas, botiquín básico.',
   NULL,
   ARRAY['planning', 'japan', 'checklist'], false),

  -- ═══ RECETAS ═══
  (uid, '11111111-1111-1111-1111-111111111102', 'imagen', 'organizado',
   'Tonkotsu Ramen Casero',
   'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&q=80',
   '{"width":800,"height":600,"format":"jpg"}',
   ARRAY['ramen', 'japanese', 'soup', 'comfort-food'], false),

  (uid, '11111111-1111-1111-1111-111111111102', 'link', 'organizado',
   'Pasta alla Norma — Recipe Video',
   'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
   '{"domain":"youtube.com","thumbnail":"https://images.unsplash.com/photo-1621996346565-e3a8d69ac5ff?w=400&q=80"}',
   ARRAY['pasta', 'italian', 'eggplant', 'video-recipe'], false),

  (uid, '11111111-1111-1111-1111-111111111102', 'texto', 'organizado',
   'Notas Masa Madre',
   'Día 1: mezclar 50g harina integral + 50g agua tibia. Día 2: descartar mitad, alimentar 50/50. Día 3-7: repetir cada 12h. Temperatura ideal 24-26°C.',
   NULL,
   ARRAY['bread', 'sourdough', 'fermentation'], false),

  -- ═══ DESIGN VAULT ═══
  (uid, '11111111-1111-1111-1111-111111111103', 'imagen', 'organizado',
   'Glassmorphism Card Kit',
   'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
   '{"width":800,"height":600,"format":"jpg","source":"dribbble"}',
   ARRAY['ui', 'glassmorphism', 'cards', 'dark-mode'], true),

  (uid, '11111111-1111-1111-1111-111111111103', 'link', 'organizado',
   'Free Figma Design System — Nucleus',
   'https://www.figma.com/community/file/nucleus-design-system',
   '{"domain":"figma.com","og_image":"https://images.unsplash.com/photo-1545235617-9465d2a55698?w=400&q=80"}',
   ARRAY['figma', 'design-system', 'ui-kit', 'free'], true),

  (uid, '11111111-1111-1111-1111-111111111103', 'texto', 'organizado',
   'Paleta Nocturna — App Collect',
   'Background: #0F0F23, Surface: #1a1a2e, Primary: #7C5CFC, Border: #2a2a40, Muted: #71717a, Foreground: #fafafa.',
   NULL,
   ARRAY['colors', 'palette', 'dark-theme'], false),

  -- ═══ MUSIC FINDS ═══
  (uid, '11111111-1111-1111-1111-111111111104', 'audio', 'organizado',
   'Chill Lo-fi Study Beat',
   'https://cdn.pixabay.com/audio/2024/11/22/audio_89eb882e1a.mp3',
   '{"duration":"02:45","format":"mp3","bpm":85,"source":"pixabay","artist":"FASSounds"}',
   ARRAY['lofi', 'study', 'chill', 'beats'], true),

  (uid, '11111111-1111-1111-1111-111111111104', 'audio', 'organizado',
   'Late Night Jazz Piano',
   'https://cdn.pixabay.com/audio/2024/09/10/audio_6e5d7e5c01.mp3',
   '{"duration":"03:22","format":"mp3","bpm":72,"source":"pixabay","artist":"MusicalMinds"}',
   ARRAY['jazz', 'piano', 'night', 'relax'], true),

  (uid, '11111111-1111-1111-1111-111111111104', 'link', 'organizado',
   'Deep Focus — Spotify Playlist',
   'https://open.spotify.com/playlist/37i9dQZF1DWZeKCadgRdKQ',
   '{"domain":"spotify.com","thumbnail":"https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&q=80"}',
   ARRAY['spotify', 'focus', 'playlist', 'productive'], true),

  -- ═══ READING LIST ═══
  (uid, '11111111-1111-1111-1111-111111111105', 'link', 'organizado',
   'Why AI Agents Will Replace Apps',
   'https://www.technologyreview.com/ai-agents-2026',
   '{"domain":"technologyreview.com","og_image":"https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&q=80"}',
   ARRAY['ai', 'agents', 'future', 'tech'], false),

  (uid, '11111111-1111-1111-1111-111111111105', 'texto', 'organizado',
   'Notas: Atomic Habits — James Clear',
   '1% mejor cada día. Sistemas > metas. Las 4 leyes: hacerlo obvio, atractivo, fácil, satisfactorio. Identidad > resultados.',
   NULL,
   ARRAY['books', 'habits', 'productivity', 'self-improvement'], false),

  -- ═══ INBOX (tablero_id NULL) ═══
  (uid, NULL, 'imagen', 'inbox',
   NULL,
   'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80',
   '{"width":800,"height":533,"format":"jpg","source":"camera_roll"}',
   NULL, false),

  (uid, NULL, 'audio', 'inbox',
   NULL,
   'https://cdn.pixabay.com/audio/2024/06/19/audio_831e538bc1.mp3',
   '{"duration":"00:15","format":"mp3","source":"voice_memo"}',
   NULL, false),

  (uid, NULL, 'texto', 'inbox',
   NULL,
   'Investigar sobre la API de Bluetooth Low Energy para el feature de Drift. Ver si se puede detectar proximidad sin GPS.',
   NULL, NULL, false),

  (uid, NULL, 'link', 'inbox',
   NULL,
   'https://developer.android.com/develop/connectivity/bluetooth/ble/ble-overview',
   '{"domain":"developer.android.com"}',
   NULL, false);

  RAISE NOTICE 'Seed completado para usuario: %', uid;
END $$;
