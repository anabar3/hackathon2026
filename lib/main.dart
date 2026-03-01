// Unnecessary import removed. All elements provided by flutter/services.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'dart:io';
import 'models/models.dart';
import 'data/mock_data.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/groq_service.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/pattern_background.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/board_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/add_screen.dart';
import 'screens/add_inbox_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/letters_screen.dart';
import 'screens/drift_screen.dart';
import 'screens/person_boards_screen.dart';
import 'screens/public_board_screen.dart';
import 'screens/board_suggestions_screen.dart';
import 'screens/public_board_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/permissions_screen.dart';
import 'services/ble_service.dart';
import 'services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'screens/board_tree_screen.dart';
import 'screens/cards_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qthjufceuesqwrypwqgx.supabase.co',
    anonKey: 'sb_publishable_lw7OkHrufOLfqCw1J4Am3A_FB601r5d',
  );
  await dotenv.load(fileName: ".env");

  await initializeBackgroundService();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CollectApp());
}

class CollectApp extends StatelessWidget {
  const CollectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

// ──────────────────────────────────────────────────
// Auth Gate — decides login vs home
// ──────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _service = SupabaseService();
  bool _permissionsGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await BleService.instance.checkPermissionsSilently();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
        _isCheckingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_service.currentUser != null) {
      if (!_permissionsGranted) {
        return PermissionsScreen(
          onGranted: () {
            setState(() {
              _permissionsGranted = true;
            });
          },
        );
      }
      return CollectHome(onLogout: () => setState(() {}));
    }
    return LoginScreen(onLoginSuccess: () => setState(() {}));
  }
}

// ──────────────────────────────────────────────────
// Main Home (after login)
// ──────────────────────────────────────────────────
class CollectHome extends StatefulWidget {
  final VoidCallback onLogout;
  const CollectHome({super.key, required this.onLogout});

  @override
  State<CollectHome> createState() => _CollectHomeState();
}

class _ModalRoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _ModalRoundedField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.foreground),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.mutedForeground),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _CollectHomeState extends State<CollectHome> {
  final _service = SupabaseService();
  Screen _screen = Screen.dashboard;
  Screen _prevScreen = Screen.dashboard;
  Board? _selectedBoard;
  Board? _selectedPublicBoard;
  late ContentItem _selectedItem;
  NearbyPerson? _selectedPerson;
  late List<ContentItem> _items;
  List<ContentItem> _publicBoardItems = [];
  List<Board> _boards = [];
  List<dynamic> _boardSuggestions = [];
  final List<String> _boardHistory = [];
  List<Map<String, dynamic>> _inboxItems = [];
  bool _loadingInbox = false;
  bool _loadingBoards = true;
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();
    _items = [];
    _selectedBoard = null;
    _selectedPerson = null;

    // Initialize BLE if we have a user
    final userId = _service.currentUser?.id;
    if (userId != null) {
      BleService.instance.init(userId);
      FlutterBackgroundService().startService();
    }

    _loadBoards();
    _loadInbox();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        _handleSharedMedia(value);
      },
      onError: (err) {
        print("getIntentDataStream error: \$err");
      },
    );

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      _handleSharedMedia(value);
      // Tell the library that we are done processing the intent.
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    BleService.instance.dispose();
    super.dispose();
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    // Process only if user is logged in
    final user = _service.currentUser;
    if (user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardando items en el Inbox...')),
    );

    bool hasError = false;

    for (var file in files) {
      try {
        if (file.type == SharedMediaType.text ||
            file.type == SharedMediaType.url) {
          final content = file.path; // path contains the text/url content
          final isLink =
              file.type == SharedMediaType.url ||
              content.startsWith('http://') ||
              content.startsWith('https://');

          if (isLink) {
            await _service.guardarLinkEnInbox(
              url: content,
              titulo: null,
              descripcion: null,
            );
          } else {
            await _service.guardarTextoEnInbox(
              contenido: content,
              titulo: null,
            );
          }
        } else {
          // It's a file (image, video, file)
          final bytes = File(file.path).readAsBytesSync();
          final fileName = file.path.split('/').last;

          String tipo = 'archivo';
          if (file.type == SharedMediaType.image) tipo = 'imagen';
          if (file.type == SharedMediaType.video) tipo = 'video';

          // Guess mime roughly or fallback
          String mime = file.mimeType ?? 'application/octet-stream';
          if (file.mimeType == null) {
            final ext = fileName.split('.').last.toLowerCase();
            if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
              mime = 'image/\$ext';
            } else if (['mp4', 'mov'].contains(ext)) {
              mime = 'video/\$ext';
            } else if (['mp3', 'wav', 'm4a'].contains(ext)) {
              mime = 'audio/\$ext';
            } else if (ext == 'pdf') {
              mime = 'application/pdf';
            }
          }

          await _service.guardarArchivoEnInbox(
            bytes: bytes,
            fileName: fileName,
            mimeType: mime,
            tipo: tipo,
            titulo: fileName,
            descripcion:
                file.message, // Optional message sent along with iOS share
            tableroId: null,
          );
        }
      } catch (e) {
        hasError = true;
        print("Error saving shared media: \$e");
      }
    }

    if (mounted) {
      if (hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error guardando algunos items.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado en el Inbox correctamente.')),
        );
      }
      // Refresh inbox to show new items
      _loadInbox();
    }
  }

  void _navigate(Screen s) {
    setState(() {
      _prevScreen = _screen;
      _screen = s;
    });
    if (s == Screen.inbox) _loadInbox();
    if (s == Screen.dashboard) _loadBoards();
  }

  void _handleBack() {
    setState(() {
      if (_screen == Screen.detail) {
        _screen = _prevScreen == Screen.detail ? Screen.board : _prevScreen;
      } else if (_screen == Screen.edit || _screen == Screen.aiOrganize) {
        _screen = Screen.board;
      } else if (_screen == Screen.publicBoard) {
        _screen = Screen.personBoards;
      } else if (_screen == Screen.boardSuggestions) {
        _screen = Screen.board;
      } else if (_screen == Screen.personBoards) {
        _screen = Screen.drift;
      } else if (_screen == Screen.profile) {
        _screen = Screen.dashboard;
      } else if (_screen == Screen.board) {
        if (_boardHistory.isNotEmpty) {
          final prevId = _boardHistory.removeLast();
          final prevBoard = _boards.where((b) => b.id == prevId);
          if (prevBoard.isNotEmpty) {
            _selectedBoard = prevBoard.first;
          }
          _prevScreen = _boardHistory.isNotEmpty
              ? Screen.board
              : Screen.dashboard;
          _screen = Screen.board;
        } else {
          _screen = _prevScreen == Screen.board
              ? Screen.dashboard
              : _prevScreen;
        }
      } else {
        _screen = Screen.dashboard;
      }
    });
  }

  void _handleBoardSelect(Board board) {
    setState(() {
      if (_screen == Screen.board && _selectedBoard != null) {
        _boardHistory.add(_selectedBoard!.id);
      } else {
        _boardHistory.clear();
      }
      _selectedBoard = board;
      _prevScreen = _screen;
      _screen = Screen.board;
    });
    // Trigger board summarize automatically when board is changed
    _backgroundAiSummarize(board.id);
  }

  Board _withUpdatedVisibility(Board board, bool isPublic) {
    return Board(
      id: board.id,
      name: board.name,
      description: board.description,
      parentId: board.parentId,
      itemCount: board.itemCount,
      coverImage: board.coverImage,
      color: board.color,
      icon: board.icon,
      isPublic: isPublic,
      isPinned: board.isPinned,
      aiSummary: board.aiSummary,
    );
  }

  Future<void> _handleToggleBoardVisibility(
    Board board,
    bool toPublic,
  ) async {
    try {
      await _service.actualizarTablero(
        tableroId: board.id,
        isPublic: toPublic,
      );

      if (!mounted) return;
      setState(() {
        _boards = _boards
            .map(
              (b) => b.id == board.id
                  ? _withUpdatedVisibility(b, toPublic)
                  : b,
            )
            .toList();

        if (_selectedBoard?.id == board.id) {
          _selectedBoard = _withUpdatedVisibility(_selectedBoard!, toPublic);
        }
        if (_selectedPublicBoard?.id == board.id) {
          _selectedPublicBoard =
              _withUpdatedVisibility(_selectedPublicBoard!, toPublic);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              toPublic ? 'Tablero marcado como público' : 'Tablero en privado',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo cambiar la visibilidad',
            ),
          ),
        );
      }
    }
  }

  void _handleItemSelect(ContentItem item) {
    setState(() {
      _selectedItem = item;
      _prevScreen = _screen;
      _screen = Screen.detail;
    });
  }

  void _handlePersonSelect(NearbyPerson person) {
    setState(() {
      _selectedPerson = person;
      _prevScreen = _screen;
      _screen = Screen.personBoards;
    });
  }

  Future<void> _handlePublicBoardSelect(
    Board board,
    NearbyPerson person,
  ) async {
    setState(() {
      _selectedPublicBoard = board;
      _publicBoardItems = [];
      _prevScreen = _screen;
      _screen = Screen.publicBoard;
    });
    try {
      final rawItems = await _service.getItemsDeTableroPublico(
        userId: person.id,
        tableroId: board.id,
      );
      if (mounted) {
        setState(() {
          _publicBoardItems = rawItems.map(_mapToContentItem).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
      }
    }
  }

  void _handleToggleSaved(String itemId) {
    setState(() {
      _items = _items.map((item) {
        if (item.id == itemId) return item.copyWith(saved: !item.saved);
        return item;
      }).toList();
      if (_selectedItem.id == itemId) {
        _selectedItem = _items.firstWhere((i) => i.id == itemId);
      }
    });
  }

  ContentItem _updatedItem(
    ContentItem item, {
    String? title,
    String? description,
    String? thumbnail,
  }) {
    return ContentItem(
      id: item.id,
      type: item.type,
      title: title ?? item.title,
      description: description ?? item.description,
      thumbnail: thumbnail ?? item.thumbnail,
      url: item.url,
      tags: item.tags,
      boardId: item.boardId,
      createdAt: item.createdAt,
      color: item.color,
      duration: item.duration,
      size: item.size,
      author: item.author,
      saved: item.saved,
    );
  }

  Future<void> _handleUpdateItemTitle(String itemId, String newTitle) async {
    await _service.actualizarItem(itemId: itemId, titulo: newTitle);
    setState(() {
      _items = _items
          .map((i) => i.id == itemId ? _updatedItem(i, title: newTitle) : i)
          .toList();
      if (_selectedItem.id == itemId) {
        _selectedItem = _items.firstWhere((i) => i.id == itemId);
      }
    });
  }

  Future<void> _handleUpdateItemDescription(
    String itemId,
    String newDescription,
  ) async {
    // We map description to the item's contenido field in Supabase.
    await _service.actualizarItem(itemId: itemId, contenido: newDescription);
    setState(() {
      _items = _items
          .map((i) => i.id == itemId
              ? _updatedItem(i, description: newDescription.isEmpty ? null : newDescription)
              : i)
          .toList();
      if (_selectedItem.id == itemId) {
        _selectedItem = _items.firstWhere((i) => i.id == itemId);
      }
    });
  }

  Future<String> _handleUpdateItemThumbnail(
    String itemId,
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    final userId = _service.currentUser?.id;
    if (userId == null) throw Exception('Debes iniciar sesión');
    final url = await _service.subirImagenPortada(
      userId: userId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    await _service.actualizarItem(
      itemId: itemId,
      rawData: {'thumbnail': url},
    );
    setState(() {
      _items = _items
          .map((i) => i.id == itemId ? _updatedItem(i, thumbnail: url) : i)
          .toList();
      if (_selectedItem.id == itemId) {
        _selectedItem = _items.firstWhere((i) => i.id == itemId);
      }
    });
    return url;
  }

  Future<void> _handleDeleteItem(String itemId) async {
    await _service.eliminarItem(itemId);
    setState(() {
      _items = _items.where((i) => i.id != itemId).toList();
      if (_selectedItem.id == itemId) {
        if (_items.isNotEmpty) {
          _selectedItem = _items.first;
        }
        _screen = _prevScreen == Screen.detail ? Screen.board : _prevScreen;
      }
    });
    _handleBack();
  }

  void _handleBoardUpdated(Board updated) {
    setState(() {
      _boards = _boards
          .map(
            (b) => b.id == updated.id
                ? Board(
                    id: updated.id,
                    name: updated.name,
                    description: updated.description,
                    parentId: updated.parentId,
                    itemCount: updated.itemCount,
                    coverImage: updated.coverImage,
                    color: updated.color,
                    icon: updated.icon,
                    isPublic: updated.isPublic,
                    isPinned: updated.isPinned,
                  )
                : b,
          )
          .toList();
      if (_selectedBoard?.id == updated.id) {
        _selectedBoard = updated;
      }
    });
  }

  void _handleBoardDeleted(String boardId) {
    setState(() {
      _boards = _boards.where((b) => b.id != boardId).toList();
      _boardHistory.removeWhere((id) => id == boardId);
      if (_selectedBoard?.id == boardId) {
        _selectedBoard = _boards.isNotEmpty ? _boards.first : null;
        _screen = Screen.dashboard;
      }
    });
  }

  Future<void> _handleLogout() async {
    BleService.instance.dispose();
    FlutterBackgroundService().invoke('stopService');
    await _service.signOut();
    widget.onLogout();
  }

  bool get _showBottomNav =>
      _screen != Screen.add &&
      _screen != Screen.detail &&
      _screen != Screen.aiOrganize &&
      _screen != Screen.edit &&
      _screen != Screen.addInbox &&
      _screen != Screen.personBoards &&
      _screen != Screen.publicBoard &&
      _screen != Screen.boardSuggestions &&
      _screen != Screen.login &&
      _screen != Screen.boardTree;

  Widget _buildScreen() {
    switch (_screen) {
      case Screen.login:
        return const SizedBox.shrink(); // handled by AuthGate
      case Screen.dashboard:
        return DashboardScreen(
          boards: _boards,
          isLoading: _loadingBoards,
          onBoardSelect: _handleBoardSelect,
          onOpenBoardTree: () => _navigate(Screen.boardTree),
          onCreateBoard: () => _openCreateBoard(),
        );
      case Screen.board:
        if (_selectedBoard == null) {
          return DashboardScreen(
            boards: _boards,
            isLoading: _loadingBoards,
            onBoardSelect: _handleBoardSelect,
            onOpenBoardTree: () => _navigate(Screen.boardTree),
            onCreateBoard: () => _openCreateBoard(),
          );
        }
        return BoardScreen(
          board: _selectedBoard!,
          items: _items,
          boards: _boards,
          onBack: _handleBack,
          onBoardSelect: _handleBoardSelect,
          onItemSelect: _handleItemSelect,
          onEdit: () => _navigate(Screen.edit),
          onCreateSubBoard: (parentId) =>
              _openCreateBoard(parentId: parentId, lockedParentId: parentId),
          onAiSummarize: _handleAiSummarize,
          onOpenSuggestions: _handleOpenSuggestions,
          onToggleVisibility: _handleToggleBoardVisibility,
        );
      case Screen.detail:
        final currentItem = _items.firstWhere(
          (i) => i.id == _selectedItem.id,
          orElse: () => _selectedItem,
        );
        final currentBoard = _boards.firstWhere(
          (b) => b.id == currentItem.boardId,
          orElse: () => _boards.isNotEmpty
              ? _boards.first
              : Board(
                  id: currentItem.boardId,
                  name: 'Board',
                  description: null,
                  parentId: null,
                  itemCount: 0,
                  coverImage: null,
                  color: '#FFFFFF',
                  icon: 'folder',
                  isPublic: false,
                ),
        );
        return DetailScreen(
          item: currentItem,
          board: currentBoard,
          onBack: _handleBack,
          onToggleSaved: _handleToggleSaved,
          onAiSummarize: () => _handleAiSummarizeItem(currentItem.id),
          onUpdateTitle: _handleUpdateItemTitle,
          onUpdateDescription: _handleUpdateItemDescription,
          onUpdateThumbnail: _handleUpdateItemThumbnail,
          onDeleteItem: _handleDeleteItem,
          onSummarize: _handleAiSummarize,
          onToggleVisibility: _handleToggleBoardVisibility,
        );
      case Screen.add:
        return AddScreen(onClose: _handleBack);
      case Screen.inbox:
        return InboxScreen(
          items: _inboxItems,
          loading: _loadingInbox,
          onRefresh: _loadInbox,
          onAdd: () => _navigate(Screen.addInbox),
        );
      case Screen.letters:
        return const LettersScreen();
      case Screen.addInbox:
        return AddInboxScreen(
          onClose: _handleBack,
          onSaved: () async {
            await _loadInbox();
            _navigate(Screen.inbox);
          },
        );
      case Screen.boardTree:
        return BoardTreeScreen(
          onBack: _handleBack,
          onCreateBoard: ({parentId}) => _openCreateBoard(parentId: parentId),
        );
      case Screen.cards:
        return CardsScreen(onBack: _handleBack);
      case Screen.drift:
        return DriftScreen(onPersonSelect: _handlePersonSelect);
      case Screen.personBoards:
        if (_selectedPerson == null) return const SizedBox.shrink();
        return PersonBoardsScreen(
          person: _selectedPerson!,
          onBack: _handleBack,
          onBoardSelect: (board) =>
              _handlePublicBoardSelect(board, _selectedPerson!),
        );
      case Screen.publicBoard:
        if (_selectedPublicBoard == null) return const SizedBox.shrink();
        return PublicBoardScreen(
          board: _selectedPublicBoard!,
          ownerName: _selectedPerson?.name ?? '',
          items: _publicBoardItems,
          myItems: _items,
          onBack: _handleBack,
          onItemSelect: _handleItemSelect,
          onExport: (item) async {
            await _service.guardarItemEnInbox(
              sourceItemId: item.id,
              sourceUserId: _selectedPerson?.id ?? '',
              titulo: item.title,
              tipo: item.type.name,
              contenido: item.description,
              url: item.url,
              thumbnailUrl: item.thumbnail,
              tags: item.tags,
            );
          },
          onSuggest: (item) async {
            if (_selectedPublicBoard == null || _selectedPerson == null) return;
            await _service.sugerirItemExistente(
              targetUserId: _selectedPerson!.id,
              itemId: item.id,
              targetTableroId: _selectedPublicBoard!.id,
            );
          },
        );
      case Screen.boardSuggestions:
        if (_selectedBoard == null) return const SizedBox.shrink();
        return BoardSuggestionsScreen(
          board: _selectedBoard!,
          suggestions: _boardSuggestions,
          onBack: _handleBack,
          onResolve: (sugId, accept) async {
            await _service.resolverSugerencia(
              sugerenciaId: sugId,
              aceptar: accept,
            );
            // Refresh
            final sugs = await _service.getSugerenciasTablero(
              _selectedBoard!.id,
            );
            setState(() {
              _boardSuggestions = sugs;
            });
            await _syncItems();
            await _loadBoards();
          },
        );
      case Screen.profile:
        return ProfileScreen(onBack: _handleBack, onLogout: _handleLogout);
      case Screen.edit:
        if (_selectedBoard == null)
          return DashboardScreen(
            boards: _boards,
            isLoading: _loadingBoards,
            onBoardSelect: _handleBoardSelect,
            onOpenBoardTree: () => _navigate(Screen.boardTree),
            onCreateBoard: () => _openCreateBoard(),
          );
        return _EditPlaceholder(
          board: _selectedBoard!,
          onBack: _handleBack,
          onUpdated: _handleBoardUpdated,
          onDeleted: _handleBoardDeleted,
        );
      case Screen.aiOrganize:
        return _AiOrganizePlaceholder(
          board: _selectedBoard ?? boards.first,
          items: _items,
          onBack: _handleBack,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _screen == Screen.dashboard,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        body: PatternBackground(
          child: SafeArea(
            bottom: false,
            child: SizedBox.expand(
              child: Stack(
                children: [
                  _buildScreen(),
                  if (_showBottomNav)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: BottomNav(
                        activeScreen: _screen,
                        onNavigate: (s) {
                          setState(() {
                            _prevScreen = _screen;
                            _screen = s;
                          });
                          if (s == Screen.inbox) _loadInbox();
                          if (s == Screen.dashboard) _loadBoards();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadInbox() async {
    final user = _service.currentUser;
    if (user == null) return;
    setState(() => _loadingInbox = true);
    try {
      final res = await _service.getItems(user.id);
      setState(() {
        _inboxItems = res.where((i) => i['estado'] == 'inbox').toList()
          ..sort(
            (a, b) => DateTime.parse(
              b['created_at'],
            ).compareTo(DateTime.parse(a['created_at'])),
          );
      });
      await _syncItems(res);
    } finally {
      if (mounted) setState(() => _loadingInbox = false);
    }
  }

  Future<void> _loadBoards({String? keepSelectedId}) async {
    final user = _service.currentUser;
    if (user == null) return;
    final res = await _service.getTableros(user.id);
    setState(() {
      _boards = res
          .map(
            (b) => Board(
              id: b['id'] as String,
              name: b['titulo'] ?? 'Sin título',
              description: b['descripcion'],
              parentId: b['parent_id'],
              itemCount: 0,
              coverImage: b['imagen_portada'],
              color: '#7C5CFC',
              icon: 'palette',
              isPublic: (b['is_public'] ?? false) as bool,
              isPinned: (b['is_pinned'] ?? false) as bool? ?? false,
              aiSummary: b['ai_summary'],
            ),
          )
          .toList();
      Board? nextSelected;
      final targetId = keepSelectedId ?? _selectedBoard?.id;
      if (targetId != null) {
        final matches = _boards.where((b) => b.id == targetId);
        if (matches.isNotEmpty) {
          nextSelected = matches.first;
        }
      }
      nextSelected ??= _selectedBoard;
      if (nextSelected == null) {
        final roots = _boards.where((b) => b.parentId == null).toList();
        nextSelected = roots.isNotEmpty ? roots.first : null;
      }
      _selectedBoard = nextSelected;
      _loadingBoards = false;
    });
    await _syncItems();
  }

  Future<void> _syncItems([List<Map<String, dynamic>>? items]) async {
    final user = _service.currentUser;
    if (user == null) return;
    final data = items ?? await _service.getItems(user.id);
    final mappedItems = data.map(_mapToContentItem).toList();

    // Rebuild board item counts from fetched items
    final counts = <String, int>{};
    for (final item in mappedItems) {
      if (item.boardId.isEmpty) continue; // inbox items have tablero_id null
      counts[item.boardId] = (counts[item.boardId] ?? 0) + 1;
    }

    setState(() {
      _items = mappedItems;
      _boards = _boards
          .map(
            (b) => Board(
              id: b.id,
              name: b.name,
              description: b.description,
              parentId: b.parentId,
              itemCount: counts[b.id] ?? 0,
              coverImage: b.coverImage,
              color: b.color,
              icon: b.icon,
              isPublic: b.isPublic,
              isPinned: b.isPinned,
              aiSummary: b.aiSummary,
            ),
          )
          .toList();

      if (_selectedBoard == null && _boards.isNotEmpty) {
        _selectedBoard = _boards.first;
      }
    });
  }

  Future<void> _handleOpenSuggestions() async {
    if (_selectedBoard == null) return;
    final sugs = await _service.getSugerenciasTablero(_selectedBoard!.id);
    setState(() {
      _boardSuggestions = sugs;
    });
    _navigate(Screen.boardSuggestions);
  }

  Future<void> _handleAiSummarize() async {
    final board = _selectedBoard;
    if (board == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating board summary...')),
    );

    try {
      await _backgroundAiSummarize(board.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Board summary generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating summary: $e')));
      }
    }
  }

  Future<void> _backgroundAiSummarize(String boardId) async {
    final user = _service.currentUser;
    if (user == null) return;

    final dbBoards = await _service.getTableros(user.id);
    final dbBoard = dbBoards.firstWhere(
      (b) => b['id'] == boardId,
      orElse: () => <String, dynamic>{},
    );
    if (dbBoard.isEmpty) return;

    final dbItems = await _service.getItemsPorTablero(
      userId: user.id,
      tableroId: boardId,
    );
    final groq = GroqService();

    // summarize items
    for (var i = 0; i < dbItems.length; i++) {
      final itemMap = dbItems[i];
      if (itemMap['ai_summary'] == null ||
          itemMap['ai_summary'].toString().isEmpty) {
        try {
          final summary = await groq.summarizeItem(itemMap);
          await _service.actualizarItem(
            itemId: itemMap['id'],
            aiSummary: summary,
          );
          itemMap['ai_summary'] = summary; // update map
        } catch (e) {
          /* ignore individual item failure in background */
        }
      }
    }

    // summarize board
    final boardSummary = await groq.summarizeBoard(dbBoard, dbItems);
    await _service.actualizarTablero(
      tableroId: boardId,
      aiSummary: boardSummary,
    );
    await _loadBoards();
  }

  Future<void> _handleAiSummarizeItem(String itemId) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generating item summary...')));
    try {
      final user = _service.currentUser;
      if (user == null) return;

      final dbItems = await _service.getItems(user.id);
      final itemMap = dbItems.firstWhere((i) => i['id'] == itemId);

      final groq = GroqService();
      final summary = await groq.summarizeItem(itemMap);
      await _service.actualizarItem(itemId: itemId, aiSummary: summary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item summary generated!')),
        );
      }
      await _syncItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating summary: $e')));
      }
    }
  }

  ContentItem _mapToContentItem(Map<String, dynamic> i) {
    final tipo = (i['tipo'] as String? ?? 'texto').toLowerCase();
    ContentType ct;
    switch (tipo) {
      case 'imagen':
        ct = ContentType.image;
        break;
      case 'audio':
        ct = ContentType.audio;
        break;
      case 'video':
        ct = ContentType.video;
        break;
      case 'link':
        ct = ContentType.link;
        break;
      case 'archivo':
      case 'file':
        ct = ContentType.file;
        break;
      default:
        ct = ContentType.note;
    }

    final title = i['titulo'] as String?;
    final contenido = i['contenido']?.toString() ?? '';
    final description =
        i['descripcion'] as String? ??
        (ct == ContentType.note || tipo == 'texto' ? contenido : null);

    String? authorName;
    if (i['autor'] != null) {
      final autor = i['autor'] as Map<String, dynamic>;
      authorName = autor['username'] ?? autor['nombre_completo'];
    }
    final thumb = i['thumbnail'] ??
        (i['metadatos'] is Map ? (i['metadatos']['thumbnail']) : null) ??
        (ct == ContentType.image ? contenido : null);
    return ContentItem(
      id: i['id'] ?? '',
      type: ct,
      title: title?.isNotEmpty == true ? title! : contenido,
      description: description,
      thumbnail: thumb,
      url: ct == ContentType.link ? contenido : null,
      tags: (i['tags'] as List?)?.cast<String>() ?? [],
      boardId: i['tablero_id'] ?? '',
      createdAt: i['created_at'] ?? '',
      color: null,
      duration: null,
      size: null,
      author: authorName,
      aiSummary: i['ai_summary'],
      saved: false,
    );
  }

  Future<void> _openCreateBoard({
    String? parentId,
    String? lockedParentId,
  }) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;
    String? coverUrl;
    Uint8List? coverBytes;
    bool uploadingCover = false;
    String? selectedParent = lockedParentId ?? parentId;
    final bool lockParent = lockedParentId != null;
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> _pickCover() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                withData: true,
              );
              final file = result?.files.first;
              final bytes = file?.bytes;
              if (bytes == null) return;

              setState(() {
                uploadingCover = true;
                coverBytes = bytes as Uint8List;
              });
              try {
                final ext = file?.extension;
                final mime = ext != null ? 'image/$ext' : 'image/jpeg';
                final userId = _service.currentUser?.id;
                if (userId == null) throw Exception('Debes iniciar sesión');
                final url = await _service.subirImagenPortada(
                  userId: userId,
                  bytes: bytes as Uint8List,
                  fileName: file?.name ?? 'cover.jpg',
                  mimeType: mime,
                );
                if (!dialogContext.mounted) return;
                setState(() => coverUrl = url);
              } catch (e) {
                // Si falla la subida (p.ej. RLS 403), mantenemos la vista previa local
                if (dialogContext.mounted) {
                  setState(() => coverUrl = null);
                }
              } finally {
                if (dialogContext.mounted) {
                  setState(() => uploadingCover = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(lockParent ? 'Nuevo subtablero' : 'Nuevo tablero'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Título',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ModalRoundedField(
                        controller: titleController,
                        onChanged: (_) => setState(() {}),
                        hint: 'Ej. Recetas de la semana',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ModalRoundedField(
                        controller: descController,
                        hint: 'Opcional, cuéntale a otros de qué va',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: uploadingCover ? null : _pickCover,
                        child: Container(
                          height: 180,
                          decoration: () {
                            final hasImage =
                                coverBytes != null || coverUrl != null;
                            return BoxDecoration(
                              color: hasImage ? null : AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: hasImage
                                  ? null
                                  : Border.all(
                                      color: AppColors.border,
                                      width: 1.5,
                                    ),
                            );
                          }(),
                          child: Stack(
                            children: [
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    height: 180,
                                    child: coverBytes != null
                                        ? Image.memory(
                                            coverBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : coverUrl != null
                                        ? Image.network(
                                            coverUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.image_outlined,
                                                size: 30,
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Sube una portada (opcional)',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.mutedForeground,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              if (uploadingCover)
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: LinearProgressIndicator(minHeight: 4),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!lockParent) ...[
                        DropdownButtonFormField<String?>(
                          value: selectedParent,
                          decoration: const InputDecoration(
                            labelText: 'Ubicación',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Nivel raíz'),
                            ),
                            ..._boards.map(
                              (b) => DropdownMenuItem<String?>(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => selectedParent = v),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Checkbox(
                            value: isPublic,
                            onChanged: (v) =>
                                setState(() => isPublic = v ?? false),
                          ),
                          const Text('Público'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      titleController.text.trim().isEmpty || uploadingCover
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
    if (created != true) return;

    final user = _service.currentUser;
    if (user == null) return;
    await _service.crearTablero(
      userId: user.id,
      titulo: titleController.text.trim(),
      descripcion: descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      imagenPortada: coverUrl,
      isPublic: isPublic,
      parentId: selectedParent,
    );
    await _loadBoards(keepSelectedId: lockedParentId ?? _selectedBoard?.id);
  }
}

// ──────────────────────────────────────────────────
// Edit Board Screen
// ──────────────────────────────────────────────────
class _EditPlaceholder extends StatefulWidget {
  final Board board;
  final VoidCallback onBack;
  final ValueChanged<Board> onUpdated;
  final ValueChanged<String> onDeleted;
  const _EditPlaceholder({
    required this.board,
    required this.onBack,
    required this.onUpdated,
    required this.onDeleted,
  });

  @override
  State<_EditPlaceholder> createState() => _EditPlaceholderState();
}

class _EditPlaceholderState extends State<_EditPlaceholder> {
  final _service = SupabaseService();
  late Board _board;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  bool _savingTitle = false;
  bool _savingDesc = false;
  bool _savingCover = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _board = widget.board;
    _titleCtrl = TextEditingController(text: widget.board.name);
    _descCtrl = TextEditingController(text: widget.board.description ?? '');
  }

  @override
  void didUpdateWidget(covariant _EditPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board.id != widget.board.id) {
      _board = widget.board;
      _titleCtrl.text = widget.board.name;
      _descCtrl.text = widget.board.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Board _copyBoard({String? name, String? description, String? cover}) {
    return Board(
      id: _board.id,
      name: name ?? _board.name,
      description: description ?? _board.description,
      parentId: _board.parentId,
      itemCount: _board.itemCount,
      coverImage: cover ?? _board.coverImage,
      color: _board.color,
      icon: _board.icon,
      isPublic: _board.isPublic,
      isPinned: _board.isPinned,
    );
  }

  void _applyUpdate(Board updated) {
    setState(() {
      _board = updated;
      _titleCtrl.text = updated.name;
      _descCtrl.text = updated.description ?? '';
    });
    widget.onUpdated(updated);
  }

  Future<void> _editTitle() async {
    if (_savingTitle) return;
    final controller = TextEditingController(text: _titleCtrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Editar título'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    final newTitle = result?.trim();
    if (newTitle == null || newTitle.isEmpty || newTitle == _board.name) return;

    setState(() => _savingTitle = true);
    try {
      await _service.actualizarTablero(tableroId: _board.id, titulo: newTitle);
      _applyUpdate(_copyBoard(name: newTitle));
      _showSnack('Título actualizado');
    } catch (_) {
      _showSnack('No se pudo actualizar el título');
    } finally {
      if (mounted) setState(() => _savingTitle = false);
    }
  }

  Future<void> _editDescription() async {
    if (_savingDesc) return;
    final controller = TextEditingController(text: _descCtrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Editar descripción'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Añade más contexto (opcional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    final newDesc = result.trim();
    final descForDb = newDesc.isEmpty ? '' : newDesc;
    if (newDesc == (_board.description ?? '')) return;

    setState(() => _savingDesc = true);
    try {
      await _service.actualizarTablero(
        tableroId: _board.id,
        descripcion: descForDb,
      );
      _applyUpdate(_copyBoard(description: newDesc.isEmpty ? null : newDesc));
      _showSnack('Descripción actualizada');
    } catch (_) {
      _showSnack('No se pudo actualizar la descripción');
    } finally {
      if (mounted) setState(() => _savingDesc = false);
    }
  }

  Future<void> _pickCover() async {
    if (_savingCover) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file == null || file.bytes == null) return;

    setState(() => _savingCover = true);
    try {
      final userId = _service.currentUser?.id;
      if (userId == null) throw Exception('Debes iniciar sesión');
      final mime = file.extension != null
          ? 'image/${file.extension}'
          : 'image/jpeg';
      final url = await _service.subirImagenPortada(
        userId: userId,
        bytes: file.bytes!,
        fileName: file.name,
        mimeType: mime,
      );
      await _service.actualizarTablero(
        tableroId: _board.id,
        imagenPortada: url,
      );
      _applyUpdate(_copyBoard(cover: url));
      _showSnack('Portada actualizada');
    } catch (_) {
      _showSnack('No se pudo actualizar la portada');
    } finally {
      if (mounted) setState(() => _savingCover = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Seguro que quieres eliminar?'),
          content: const Text(
            'Se eliminará el tablero y todos sus items. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _service.eliminarTableroConItems(_board.id);
      _showSnack('Tablero eliminado');
      widget.onDeleted(_board.id);
    } catch (_) {
      _showSnack('No se pudo eliminar el tablero');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _editIcon({required VoidCallback onTap, required bool loading}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.muted.withAlpha(60),
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.edit_outlined,
                color: AppColors.mutedForeground,
                size: 16,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header: back, title, Done
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.foreground,
                    size: 18,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Editar tablero',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onBack,
                child: const Text(
                  'Listo',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.border, height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DETALLES DEL TABLERO',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Título',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _board.name,
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _editIcon(onTap: _editTitle, loading: _savingTitle),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _board.description?.isNotEmpty == true
                                      ? _board.description!
                                      : 'Sin descripción',
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _editIcon(
                            onTap: _editDescription,
                            loading: _savingDesc,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PORTADA',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _board.coverImage != null
                          ? Image.network(
                              _board.coverImage!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppColors.muted.withAlpha(60),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: AppColors.mutedForeground,
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.muted.withAlpha(60),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: AppColors.mutedForeground,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _editIcon(
                        onTap: _pickCover,
                        loading: _savingCover,
                      ),
                    ),
                    if (_savingCover)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Los cambios se guardan al instante.',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _deleting ? null : _confirmDelete,
                    child: _deleting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Borrar tablero',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// AI Organize Screen placeholder
// ──────────────────────────────────────────────────
class _AiOrganizePlaceholder extends StatefulWidget {
  final Board board;
  final List<ContentItem> items;
  final VoidCallback onBack;
  const _AiOrganizePlaceholder({
    required this.board,
    required this.items,
    required this.onBack,
  });

  @override
  State<_AiOrganizePlaceholder> createState() => _AiOrganizePlaceholderState();
}

class _AiOrganizePlaceholderState extends State<_AiOrganizePlaceholder> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.foreground,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Organize',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _done
                      ? 'Board optimized!'
                      : 'Analyzing "${widget.board.name}"...',
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _done
                      ? 'AI has reorganized your content for better discovery.'
                      : 'AI is finding patterns in your content.',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_done) ...[
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: widget.onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Accept Changes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
