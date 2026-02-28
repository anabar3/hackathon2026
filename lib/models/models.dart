enum ContentType { image, video, link, audio, note, document, file }

enum Screen {
  login,
  dashboard,
  inbox,
  boardTree,
  board,
  detail,
  add,
  addInbox,
  edit,
  drift,
  aiOrganize,
  personBoards,
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
  final List<Board> publicBoards;

  const NearbyPerson({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.lastSeenLocation,
    required this.lastSeenTime,
    required this.sharedInterests,
    required this.publicBoards,
  });
}
