enum ContentType { image, video, link, audio, note, document, file }

enum Screen {
  login,
  dashboard,
  inbox,
  letters,
  boardTree,
  cards,
  board,
  detail,
  add,
  addInbox,
  edit,
  drift,
  aiOrganize,
  personBoards,
  publicBoard,
  boardSuggestions,
  profile,
}

class ContentItem {
  final String id;
  final ContentType type;
  final String title;
  final String? description;
  final String? thumbnail;
  final String? url;
  final List<String> tags;
  final String boardId;
  final String createdAt;
  final String? color;
  final String? duration;
  final String? size;
  final String? author;
  final String? aiSummary;
  bool saved;

  ContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.thumbnail,
    this.url,
    required this.tags,
    required this.boardId,
    required this.createdAt,
    this.color,
    this.duration,
    this.size,
    this.author,
    this.aiSummary,
    required this.saved,
  });

  ContentItem copyWith({bool? saved}) {
    return ContentItem(
      id: id,
      type: type,
      title: title,
      description: description,
      thumbnail: thumbnail,
      url: url,
      tags: tags,
      boardId: boardId,
      createdAt: createdAt,
      color: color,
      duration: duration,
      size: size,
      author: author,
      aiSummary: aiSummary,
      saved: saved ?? this.saved,
    );
  }
}

class Board {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final int itemCount;
  final String? coverImage;
  final String color;
  final String icon;
  final bool isPublic;
  final bool isPinned;
  final String? aiSummary;

  const Board({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.itemCount,
    this.coverImage,
    required this.color,
    required this.icon,
    required this.isPublic,
    this.isPinned = false,
    this.aiSummary,
  });
}

class NearbyPerson {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final String lastSeenLocation;
  final String lastSeenTime;
  final List<String> sharedInterests;
  final String? sharedInterestsSummary;
  final int? compatibilityScore;
  final List<Board> publicBoards;

  const NearbyPerson({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.lastSeenLocation,
    required this.lastSeenTime,
    required this.sharedInterests,
    this.sharedInterestsSummary,
    this.compatibilityScore,
    required this.publicBoards,
  });

  /// Build from a Supabase encounter row with joined profile.
  factory NearbyPerson.fromEncuentro(
    Map<String, dynamic> row, {
    List<Board> boards = const [],
    List<String> myInterests = const [],
  }) {
    final perfil = row['usuario_encontrado'] as Map<String, dynamic>? ?? {};
    final vistoEn = DateTime.tryParse(row['visto_en'] ?? '') ?? DateTime.now();
    final diff = DateTime.now().difference(vistoEn);

    String timeAgo;
    if (diff.inMinutes < 60) {
      timeAgo = 'hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      timeAgo = 'hace ${diff.inHours} h';
    } else {
      timeAgo = 'hace ${diff.inDays} d';
    }

    final theirInterests = List<String>.from(perfil['intereses'] ?? []);
    final shared = theirInterests
        .where((i) => myInterests.contains(i))
        .toList();

    return NearbyPerson(
      id: perfil['id'] ?? row['usuario_encontrado_id'] ?? '',
      name: perfil['nombre_completo'] ?? perfil['username'] ?? 'Unknown',
      avatar: perfil['avatar_url'] ?? '',
      bio: perfil['bio'] ?? '',
      lastSeenLocation: row['ubicacion'] ?? 'Cerca',
      lastSeenTime: timeAgo,
      sharedInterests: shared,
      sharedInterestsSummary: row['shared_interests_summary'],
      compatibilityScore: row['compatibility_score'],
      publicBoards: boards,
    );
  }
}
