import '../models/models.dart';

final List<Board> boards = [
  const Board(
    id: 'travel',
    name: 'Travel Inspo',
    description: 'Dream destinations and travel photography',
    itemCount: 24,
    coverImage:
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800&q=80',
    color: '#7c3aed33',
    icon: 'compass',
    isPublic: true,
  ),
  const Board(
    id: 'design',
    name: 'Design System',
    description: 'UI patterns, components, and references',
    itemCount: 18,
    coverImage:
        'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    color: '#1e1e32',
    icon: 'palette',
    isPublic: false,
  ),
  const Board(
    id: 'recipes',
    name: 'Recipes',
    description: 'Favorite recipes and food photography',
    itemCount: 31,
    coverImage:
        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&q=80',
    color: '#7c3aed1a',
    icon: 'chef_hat',
    isPublic: true,
  ),
  const Board(
    id: 'nature',
    name: 'Nature',
    description: 'Landscapes and wildlife photography',
    itemCount: 15,
    coverImage:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
    color: '#1e1e32',
    icon: 'mountain',
    isPublic: true,
  ),
  const Board(
    id: 'architecture',
    name: 'Architecture',
    description: 'Modern buildings and urban design',
    itemCount: 12,
    coverImage:
        'https://images.unsplash.com/photo-1487958449943-2429e8be8625?w=800&q=80',
    color: '#7c3aed33',
    icon: 'building',
    isPublic: false,
  ),
  const Board(
    id: 'reading',
    name: 'Reading List',
    description: 'Articles, books, and research papers',
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
    title: 'Maldives Sunset Beach',
    description:
        'Crystal clear waters with overwater bungalows during golden hour',
    thumbnail:
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&q=80',
    tags: ['travel', 'beach', 'sunset'],
    boardId: 'travel',
    createdAt: '2026-02-25',
    author: 'Nature Gallery',
    saved: true,
  ),
  ContentItem(
    id: '2',
    type: ContentType.video,
    title: 'UI Animation Patterns',
    description:
        'A comprehensive guide to micro-interactions in modern interfaces',
    thumbnail:
        'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600&q=80',
    tags: ['design', 'animation', 'ui'],
    boardId: 'design',
    createdAt: '2026-02-24',
    duration: '12:34',
    author: 'Design Weekly',
    saved: false,
  ),
  ContentItem(
    id: '3',
    type: ContentType.link,
    title: 'The Future of CSS',
    description:
        'Exploring new CSS features coming in 2026 including container queries',
    url: 'https://example.com/future-css',
    thumbnail:
        'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=600&q=80',
    tags: ['css', 'web', 'development'],
    boardId: 'design',
    createdAt: '2026-02-23',
    author: 'Web Trends',
    saved: true,
  ),
  ContentItem(
    id: '4',
    type: ContentType.audio,
    title: 'Ambient Rain Sounds',
    description:
        'Relaxing rain and thunder ambient audio for focus and relaxation',
    tags: ['ambient', 'focus', 'nature'],
    boardId: 'nature',
    createdAt: '2026-02-22',
    duration: '45:00',
    saved: false,
  ),
  ContentItem(
    id: '5',
    type: ContentType.note,
    title: 'Trip Packing List',
    description:
        'Essential items for the upcoming Bali trip: passport, sunscreen, camera gear, hiking boots, waterproof bag',
    tags: ['travel', 'planning'],
    boardId: 'travel',
    createdAt: '2026-02-21',
    saved: true,
  ),
  ContentItem(
    id: '6',
    type: ContentType.image,
    title: 'Tuscan Countryside',
    description:
        'Rolling hills of Tuscany with golden wheat fields and cypress trees',
    thumbnail:
        'https://images.unsplash.com/photo-1523531294919-4bcd7c65e216?w=600&q=80',
    tags: ['travel', 'landscape', 'italy'],
    boardId: 'travel',
    createdAt: '2026-02-20',
    author: 'Euro Travel',
    saved: false,
  ),
  ContentItem(
    id: '7',
    type: ContentType.document,
    title: 'Brand Guidelines v2',
    description:
        'Updated brand guidelines including new color palette and typography scale',
    tags: ['design', 'branding'],
    boardId: 'design',
    createdAt: '2026-02-19',
    size: '4.2 MB',
    saved: true,
  ),
  ContentItem(
    id: '8',
    type: ContentType.image,
    title: 'Sourdough Bread',
    description: 'Homemade artisan sourdough with a perfect golden crust',
    thumbnail:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80',
    tags: ['food', 'baking', 'bread'],
    boardId: 'recipes',
    createdAt: '2026-02-18',
    author: 'Bake Studio',
    saved: false,
  ),
  ContentItem(
    id: '9',
    type: ContentType.link,
    title: '10 Hidden Gems in Portugal',
    description:
        'Discover the lesser-known beautiful spots across Portugal\'s coastline',
    url: 'https://example.com/portugal-gems',
    thumbnail:
        'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=600&q=80',
    tags: ['travel', 'portugal', 'guide'],
    boardId: 'travel',
    createdAt: '2026-02-17',
    author: 'Travel Mag',
    saved: true,
  ),
  ContentItem(
    id: '10',
    type: ContentType.image,
    title: 'Modern Glass Tower',
    description:
        'Contemporary skyscraper with reflective glass facade against blue sky',
    thumbnail:
        'https://images.unsplash.com/photo-1487958449943-2429e8be8625?w=600&q=80',
    tags: ['architecture', 'modern', 'urban'],
    boardId: 'architecture',
    createdAt: '2026-02-16',
    author: 'Arch Digest',
    saved: false,
  ),
  ContentItem(
    id: '11',
    type: ContentType.file,
    title: 'Project Assets.zip',
    description:
        'Exported design assets including icons, illustrations and UI components',
    tags: ['design', 'assets'],
    boardId: 'design',
    createdAt: '2026-02-15',
    size: '128 MB',
    saved: false,
  ),
  ContentItem(
    id: '12',
    type: ContentType.image,
    title: 'Abstract Textures',
    description:
        'Bold contemporary art with warm earth tones and textured canvas',
    thumbnail:
        'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=600&q=80',
    tags: ['art', 'abstract', 'texture'],
    boardId: 'reading',
    createdAt: '2026-02-14',
    author: 'Art Studio',
    saved: true,
  ),
  ContentItem(
    id: '13',
    type: ContentType.note,
    title: 'Color Theory Notes',
    description:
        'Key takeaways from the color theory workshop: complementary vs analogous palettes',
    tags: ['design', 'color', 'notes'],
    boardId: 'design',
    createdAt: '2026-02-13',
    saved: false,
  ),
  ContentItem(
    id: '14',
    type: ContentType.video,
    title: 'Northern Lights Timelapse',
    description: 'Stunning aurora borealis captured over the Norwegian fjords',
    thumbnail:
        'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=600&q=80',
    tags: ['nature', 'timelapse', 'norway'],
    boardId: 'nature',
    createdAt: '2026-02-12',
    duration: '3:22',
    author: 'Arctic Films',
    saved: true,
  ),
  ContentItem(
    id: '15',
    type: ContentType.link,
    title: 'Thai Green Curry Recipe',
    description: 'Authentic Thai green curry with homemade paste from scratch',
    url: 'https://example.com/thai-curry',
    thumbnail:
        'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=600&q=80',
    tags: ['food', 'thai', 'curry'],
    boardId: 'recipes',
    createdAt: '2026-02-11',
    author: 'Serious Eats',
    saved: false,
  ),
  ContentItem(
    id: '16',
    type: ContentType.image,
    title: 'Japanese Garden',
    description: 'Serene zen garden with raked gravel and bonsai trees',
    thumbnail:
        'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600&q=80',
    tags: ['nature', 'japan', 'zen'],
    boardId: 'nature',
    createdAt: '2026-02-10',
    author: 'Zen Collection',
    saved: false,
  ),
];
