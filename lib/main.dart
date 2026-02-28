import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'models/models.dart';
import 'data/mock_data.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'widgets/bottom_nav.dart';
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

class _CollectHomeState extends State<CollectHome> {
  final _service = SupabaseService();
  Screen _screen = Screen.dashboard;
  Screen _prevScreen = Screen.dashboard;
  Board? _selectedBoard;
  late ContentItem _selectedItem;
  NearbyPerson? _selectedPerson;
  late List<ContentItem> _items;
  List<Board> _boards = [];
  List<Map<String, dynamic>> _inboxItems = [];
  bool _loadingInbox = false;

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
  }

  @override
  void dispose() {
    BleService.instance.dispose();
    super.dispose();
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
      } else if (_screen == Screen.personBoards) {
        _screen = Screen.drift;
      } else if (_screen == Screen.profile) {
        _screen = Screen.dashboard;
      } else {
        _screen = Screen.dashboard;
      }
    });
  }

  void _handleBoardSelect(Board board) {
    setState(() {
      _selectedBoard = board;
      _prevScreen = _screen;
      _screen = Screen.board;
    });
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
      _screen != Screen.login &&
      _screen != Screen.boardTree;

  Widget _buildScreen() {
    switch (_screen) {
      case Screen.login:
        return const SizedBox.shrink(); // handled by AuthGate
      case Screen.dashboard:
        return DashboardScreen(
          boards: _boards,
          onBoardSelect: _handleBoardSelect,
          onOpenBoardTree: () => _navigate(Screen.boardTree),
          onCreateBoard: () => _openCreateBoard(),
        );
      case Screen.board:
        if (_selectedBoard == null) {
          return DashboardScreen(
            boards: _boards,
            onBoardSelect: _handleBoardSelect,
            onOpenBoardTree: () => _navigate(Screen.boardTree),
            onCreateBoard: () => _openCreateBoard(),
          );
        }
        return BoardScreen(
          board: _selectedBoard!,
          items: _items,
          onBack: _handleBack,
          onItemSelect: _handleItemSelect,
          onEdit: () => _navigate(Screen.edit),
          onAiOrganize: () => _navigate(Screen.aiOrganize),
        );
      case Screen.detail:
        final currentItem = _items.firstWhere(
          (i) => i.id == _selectedItem.id,
          orElse: () => _selectedItem,
        );
        return DetailScreen(
          item: currentItem,
          onBack: _handleBack,
          onToggleSaved: _handleToggleSaved,
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
        );
      case Screen.profile:
        return ProfileScreen(onBack: _handleBack, onLogout: _handleLogout);
      case Screen.edit:
        if (_selectedBoard == null)
          return DashboardScreen(
            boards: _boards,
            onBoardSelect: _handleBoardSelect,
            onOpenBoardTree: () => _navigate(Screen.boardTree),
            onCreateBoard: () => _openCreateBoard(),
          );
        return _EditPlaceholder(board: _selectedBoard!, onBack: _handleBack);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
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

  Future<void> _loadBoards() async {
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
            ),
          )
          .toList();
      final roots = _boards.where((b) => b.parentId == null).toList();
      _selectedBoard = roots.isNotEmpty ? roots.first : null;
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
            ),
          )
          .toList();

      if (_selectedBoard == null && _boards.isNotEmpty) {
        _selectedBoard = _boards.first;
      }
    });
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
    return ContentItem(
      id: i['id'] ?? '',
      type: ct,
      title: title?.isNotEmpty == true ? title! : contenido,
      description: null,
      thumbnail: null,
      url: ct == ContentType.link ? contenido : null,
      tags: (i['tags'] as List?)?.cast<String>() ?? [],
      boardId: i['tablero_id'] ?? '',
      createdAt: i['created_at'] ?? '',
      color: null,
      duration: null,
      size: null,
      author: null,
      saved: false,
    );
  }

  Future<void> _openCreateBoard({String? parentId}) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;
    String? coverUrl;
    bool uploadingCover = false;
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

              setState(() => uploadingCover = true);
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
              title: const Text('Nuevo tablero'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej. Recetas de la semana',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Opcional, cuéntale a otros de qué va',
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: uploadingCover ? null : _pickCover,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (coverUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  coverUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            else
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 30,
                                      color: AppColors.mutedForeground,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Sube una portada (opcional)',
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: parentId,
                      decoration: const InputDecoration(labelText: 'Ubicación'),
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
                      onChanged: (v) => setState(() => parentId = v),
                    ),
                    const SizedBox(height: 8),
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
      parentId: parentId,
    );
    await _loadBoards();
  }
}

// ──────────────────────────────────────────────────
// Edit Board Screen
// ──────────────────────────────────────────────────
class _EditPlaceholder extends StatelessWidget {
  final Board board;
  final VoidCallback onBack;
  const _EditPlaceholder({required this.board, required this.onBack});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'link':
        return Icons.link;
      case 'audio':
        return Icons.headphones;
      case 'note':
        return Icons.sticky_note_2_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // Sample items for display
  static const _sampleItems = [
    (
      'Maldives Sunset Beach',
      'Image',
      'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=100&q=60',
    ),
    ('Trip Packing List', 'Note', null),
    (
      'Tuscan Countryside',
      'Image',
      'https://images.unsplash.com/photo-1523531294919-4bcd7c65e216?w=100&q=60',
    ),
    ('Flight Booking Tips', 'Link', null),
  ];

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
                onTap: onBack,
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
                    'Edit Board',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onBack,
                child: const Text(
                  'Done',
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
                // BOARD DETAILS section
                const Text(
                  'BOARD DETAILS',
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
                      // Name field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Name',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  board.name,
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.muted.withAlpha(60),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.mutedForeground,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 24),
                      // Description field
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        board.description ?? 'No description',
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // COVER IMAGE section
                const Text(
                  'COVER IMAGE',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: board.coverImage != null
                      ? Image.network(
                          board.coverImage!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
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
                          height: 160,
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
                const SizedBox(height: 24),
                // ITEMS section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ITEMS (${_sampleItems.length})',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Select All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._sampleItems.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        // Drag handle
                        const Icon(
                          Icons.drag_indicator,
                          color: AppColors.mutedForeground,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        // Checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.$3 != null
                              ? Image.network(
                                  item.$3!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: AppColors.primary.withAlpha(20),
                                    child: Icon(
                                      _typeIcon(item.$2.toLowerCase()),
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _typeIcon(item.$2.toLowerCase()),
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Title + type
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: const TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
