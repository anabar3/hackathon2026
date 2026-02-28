import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'screens/drift_screen.dart';
import 'screens/person_boards_screen.dart';
import 'screens/profile_screen.dart';
import 'services/ble_service.dart';
import 'services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'screens/inbox_screen.dart';
import 'screens/board_tree_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qthjufceuesqwrypwqgx.supabase.co',
    anonKey: 'sb_publishable_lw7OkHrufOLfqCw1J4Am3A_FB601r5d',
  );

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

  @override
  Widget build(BuildContext context) {
    if (_service.currentUser != null) {
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
  late Board _selectedBoard;
  late ContentItem _selectedItem;
  late NearbyPerson? _selectedPerson;
  late List<ContentItem> _items;
  List<Board> _boards = boards;
  List<Map<String, dynamic>> _inboxItems = [];
  bool _loadingInbox = false;

  @override
  void initState() {
    super.initState();
    _items = buildContentItems();
    _selectedBoard = boards.first;
    _selectedPerson = null;

    // Initialize BLE if we have a user
    final userId = _service.currentUser?.id;
    if (userId != null) {
      BleService.instance.init(userId);
      FlutterBackgroundService().startService();
    }
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
      _screen != Screen.login;

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
        return BoardScreen(
          board: _selectedBoard,
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
        return _EditPlaceholder(board: _selectedBoard, onBack: _handleBack);
      case Screen.aiOrganize:
        return _AiOrganizePlaceholder(
          board: _selectedBoard,
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
                  },
                  onAdd: () => _navigate(Screen.add),
                  onAddInbox: () => _navigate(Screen.addInbox),
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
            ),
          )
          .toList();
      final roots = _boards.where((b) => b.parentId == null).toList();
      if (roots.isNotEmpty) _selectedBoard = roots.first;
    });
  }

  Future<void> _openCreateBoard({String? parentId}) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Nuevo tablero'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isPublic,
                    onChanged: (v) {
                      isPublic = v ?? false;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Text('Público'),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: parentId,
                decoration: const InputDecoration(
                  labelText: 'Dentro de (opcional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nivel raíz'),
                  ),
                  ..._boards.map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ),
                ],
                onChanged: (v) {
                  parentId = v;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Crear'),
            ),
          ],
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
      isPublic: isPublic,
      parentId: parentId,
    );
    await _loadBoards();
  }
}

// ──────────────────────────────────────────────────
// Edit Screen placeholder
// ──────────────────────────────────────────────────
class _EditPlaceholder extends StatelessWidget {
  final Board board;
  final VoidCallback onBack;
  const _EditPlaceholder({required this.board, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    Icons.close,
                    color: AppColors.foreground,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Board',
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NAME',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    board.name,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    board.description ?? '',
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
