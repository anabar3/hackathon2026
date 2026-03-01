import '../models/models.dart';

final List<Board> boards = [
  const Board(
    id: 'travel',
    name: 'Inspo de viajes',
    description: 'Destinos de ensueño y fotografía de viajes',
    itemCount: 24,
    coverImage:
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800&q=80',
    color: '#7c3aed33',
    icon: 'compass',
    isPublic: true,
  ),
  const Board(
    id: 'design',
    name: 'Sistema de diseño',
    description: 'Patrones de UI, componentes y referencias',
    itemCount: 18,
    coverImage:
        'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    color: '#1e1e32',
    icon: 'palette',
    isPublic: false,
  ),
  const Board(
    id: 'recipes',
    name: 'Recetas',
    description: 'Recetas favoritas y fotos de comida',
    itemCount: 31,
    coverImage:
        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&q=80',
    color: '#7c3aed1a',
    icon: 'chef_hat',
    isPublic: true,
  ),
  const Board(
    id: 'nature',
    name: 'Naturaleza',
    description: 'Paisajes y fotografía de vida salvaje',
    itemCount: 15,
    coverImage:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
    color: '#1e1e32',
    icon: 'mountain',
    isPublic: true,
  ),
  const Board(
    id: 'architecture',
    name: 'Arquitectura',
    description: 'Edificios modernos y diseño urbano',
    itemCount: 12,
    coverImage:
        'https://images.unsplash.com/photo-1487958449943-2429e8be8625?w=800&q=80',
    color: '#7c3aed33',
    icon: 'building',
    isPublic: false,
  ),
  const Board(
    id: 'reading',
    name: 'Lista de lectura',
    description: 'Artículos, libros y papers de investigación',
    itemCount: 9,
    coverImage:
        'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=800&q=80',
    color: '#1e1e32',
    icon: 'book_open',
    isPublic: true,
  ),
];

List<ContentItem> buildContentItems() => [
  ContentItem(
    id: '1',
    type: ContentType.image,
    title: 'Playa al atardecer en Maldivas',
    description:
        'Aguas cristalinas con bungalows sobre el mar durante la hora dorada',
    thumbnail:
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&q=80',
    tags: ['viajes', 'playa', 'atardecer'],
    boardId: 'travel',
    createdAt: '2026-02-25',
    author: 'Nature Gallery',
    saved: true,
  ),
  ContentItem(
    id: '2',
    type: ContentType.video,
    title: 'Patrones de animación UI',
    description:
        'Guía completa de microinteracciones en interfaces modernas',
    thumbnail:
        'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600&q=80',
    tags: ['diseño', 'animación', 'ui'],
    boardId: 'design',
    createdAt: '2026-02-24',
    duration: '12:34',
    author: 'Design Weekly',
    saved: false,
  ),
  ContentItem(
    id: '3',
    type: ContentType.link,
    title: 'El futuro de CSS',
    description:
        'Explorando las nuevas funciones de CSS en 2026, incluidas container queries',
    url: 'https://example.com/future-css',
    thumbnail:
        'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=600&q=80',
    tags: ['css', 'web', 'desarrollo'],
    boardId: 'design',
    createdAt: '2026-02-23',
    author: 'Tendencias Web',
    saved: true,
  ),
  ContentItem(
    id: '4',
    type: ContentType.audio,
    title: 'Sonidos de lluvia ambiente',
    description:
        'Audio relajante de lluvia y truenos para foco y relajación',
    tags: ['ambiente', 'foco', 'naturaleza'],
    boardId: 'nature',
    createdAt: '2026-02-22',
    duration: '45:00',
    saved: false,
  ),
  ContentItem(
    id: '5',
    type: ContentType.note,
    title: 'Lista de equipaje',
    description:
        'Elementos esenciales para el próximo viaje a Bali: pasaporte, bloqueador, cámara, botas y bolsa impermeable',
    tags: ['viajes', 'planeación'],
    boardId: 'travel',
    createdAt: '2026-02-21',
    saved: true,
  ),
  ContentItem(
    id: '6',
    type: ContentType.image,
    title: 'Campo toscano',
    description:
        'Colinas de la Toscana con campos dorados de trigo y cipreses',
    thumbnail:
        'https://images.unsplash.com/photo-1523531294919-4bcd7c65e216?w=600&q=80',
    tags: ['viajes', 'paisaje', 'italia'],
    boardId: 'travel',
    createdAt: '2026-02-20',
    author: 'Viajes Euro',
    saved: false,
  ),
  ContentItem(
    id: '7',
    type: ContentType.document,
    title: 'Guía de marca v2',
    description:
        'Guía de marca actualizada con nueva paleta de colores y escala tipográfica',
    tags: ['diseño', 'branding'],
    boardId: 'design',
    createdAt: '2026-02-19',
    size: '4.2 MB',
    saved: true,
  ),
  ContentItem(
    id: '8',
    type: ContentType.image,
    title: 'Pan de masa madre',
    description: 'Pan artesanal con corteza dorada perfecta',
    thumbnail:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80',
    tags: ['comida', 'panadería', 'pan'],
    boardId: 'recipes',
    createdAt: '2026-02-18',
    author: 'Bake Studio',
    saved: false,
  ),
  ContentItem(
    id: '9',
    type: ContentType.link,
    title: '10 joyas ocultas en Portugal',
    description:
        'Descubre los rincones menos conocidos a lo largo de la costa portuguesa',
    url: 'https://example.com/portugal-gems',
    thumbnail:
        'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=600&q=80',
    tags: ['viajes', 'portugal', 'guía'],
    boardId: 'travel',
    createdAt: '2026-02-17',
    author: 'Revista Travel',
    saved: true,
  ),
  ContentItem(
    id: '10',
    type: ContentType.image,
    title: 'Torre moderna de vidrio',
    description:
        'Rascacielos contemporáneo con fachada de vidrio reflectante',
    thumbnail:
        'https://images.unsplash.com/photo-1487958449943-2429e8be8625?w=600&q=80',
    tags: ['arquitectura', 'moderno', 'urbano'],
    boardId: 'architecture',
    createdAt: '2026-02-16',
    author: 'Arch Digest',
    saved: false,
  ),
  ContentItem(
    id: '11',
    type: ContentType.file,
    title: 'Assets del proyecto.zip',
    description:
        'Recursos de diseño exportados: íconos, ilustraciones y componentes UI',
    tags: ['diseño', 'assets'],
    boardId: 'design',
    createdAt: '2026-02-15',
    size: '128 MB',
    saved: false,
  ),
  ContentItem(
    id: '12',
    type: ContentType.image,
    title: 'Texturas abstractas',
    description:
        'Arte contemporáneo audaz con tonos tierra cálidos y lienzo texturizado',
    thumbnail:
        'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=600&q=80',
    tags: ['arte', 'abstracto', 'textura'],
    boardId: 'reading',
    createdAt: '2026-02-14',
    author: 'Art Studio',
    saved: true,
  ),
  ContentItem(
    id: '13',
    type: ContentType.note,
    title: 'Notas de teoría del color',
    description:
        'Ideas clave del taller: paletas complementarias vs análogas',
    tags: ['diseño', 'color', 'notas'],
    boardId: 'design',
    createdAt: '2026-02-13',
    saved: false,
  ),
  ContentItem(
    id: '14',
    type: ContentType.video,
    title: 'Time‑lapse de auroras',
    description: 'Impresionantes auroras boreales sobre los fiordos noruegos',
    thumbnail:
        'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=600&q=80',
    tags: ['naturaleza', 'timelapse', 'noruega'],
    boardId: 'nature',
    createdAt: '2026-02-12',
    duration: '3:22',
    author: 'Arctic Films',
    saved: true,
  ),
  ContentItem(
    id: '15',
    type: ContentType.link,
    title: 'Receta de curry verde thai',
    description: 'Curry verde tailandés auténtico con pasta casera',
    url: 'https://example.com/thai-curry',
    thumbnail:
        'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=600&q=80',
    tags: ['comida', 'thai', 'curry'],
    boardId: 'recipes',
    createdAt: '2026-02-11',
    author: 'Serious Eats',
    saved: false,
  ),
  ContentItem(
    id: '16',
    type: ContentType.image,
    title: 'Jardín japonés',
    description: 'Sereno jardín zen con grava rastrillada y bonsáis',
    thumbnail:
        'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600&q=80',
    tags: ['naturaleza', 'japón', 'zen'],
    boardId: 'nature',
    createdAt: '2026-02-10',
    author: 'Zen Collection',
    saved: false,
  ),
];
