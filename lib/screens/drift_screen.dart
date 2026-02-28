import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/ble_service.dart';
import '../widgets/animated_entry.dart';

class DriftScreen extends StatefulWidget {
  final void Function(NearbyPerson) onPersonSelect;

  const DriftScreen({super.key, required this.onPersonSelect});

  @override
  State<DriftScreen> createState() => _DriftScreenState();
}

class _DriftScreenState extends State<DriftScreen> {
  final _service = SupabaseService();
  List<NearbyPerson> _nearPeople = [];
  List<NearbyPerson> _walkedPeople = [];
  Timer? _walkedDebounce;
  bool _loadingWalked = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    BleService.instance.nearbyUsers.addListener(_onNearbyUsersChanged);
    BleService.instance.onUserLeft = _onUserLeft;
    _onNearbyUsersChanged(); // Initial sync
    _loadWalkedEncounters(); // Load Walked people from Supabase
  }

  Future<void> _loadWalkedEncounters() async {
    if (_loadingWalked) return; // Avoid overlapping calls
    _loadingWalked = true;
    final myUserId = _service.currentUser?.id;
    if (myUserId == null) {
      _loadingWalked = false;
      return;
    }

    try {
      final encounters = await _service.getEncuentros(myUserId);
      print('[DriftScreen] Loaded ${encounters.length} encounters from DB');
      final myProfile = await _service.getPerfil(myUserId);
      final myInterests = List<String>.from(myProfile?['intereses'] ?? []);

      List<NearbyPerson> walked = [];
      for (final enc in encounters) {
        final profile = enc['usuario_encontrado'];
        if (profile == null) {
          print('[DriftScreen] Encounter has null profile, skipping');
          continue;
        }
        final id = profile['id'];

        // Skip if currently near
        if (BleService.instance.nearbyUsers.value.contains(id)) {
          print('[DriftScreen] Skipping $id — currently near');
          continue;
        }

        List<Board> boards = [];
        try {
          final boardsData = await _service.getTablerosPublicos(id);
          boards = boardsData
              .map(
                (b) => Board(
                  id: b['id'] ?? '',
                  name: b['titulo'] ?? '',
                  description: b['descripcion'],
                  itemCount: 0,
                  coverImage: b['imagen_portada'],
                  color: '#1e1e32',
                  icon: 'compass',
                  isPublic: true,
                ),
              )
              .toList();
        } catch (_) {}

        final theirInterests = List<String>.from(profile['intereses'] ?? []);
        final shared = theirInterests
            .where((i) => myInterests.contains(i))
            .toList();

        // Simple human readable time for 'visto_en'
        final timestamp = DateTime.tryParse(enc['visto_en'] ?? '');
        final lastSeenTime = timestamp != null
            ? _formatTimeAgo(timestamp)
            : 'Earlier';

        walked.add(
          NearbyPerson(
            id: id,
            name:
                profile['nombre_completo'] ??
                profile['username'] ??
                'Anonymous',
            avatar: profile['avatar_url'] ?? '',
            bio: profile['bio'] ?? '',
            lastSeenLocation: 'Crossed path',
            lastSeenTime: lastSeenTime,
            sharedInterests: shared,
            publicBoards: boards,
          ),
        );
      }

      // Filter out anyone currently in the near list to avoid duplication
      final nearIds = _nearPeople.map((p) => p.id).toSet();
      walked.removeWhere((p) => nearIds.contains(p.id));

      print('[DriftScreen] Final walked list: ${walked.length} people');
      if (mounted) {
        setState(() {
          _walkedPeople = walked;
          _initialLoading = false;
        });
      }
    } catch (e) {
      print('[DriftScreen] ERROR loading walked: $e');
      if (mounted) setState(() => _initialLoading = false);
    } finally {
      _loadingWalked = false;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  @override
  void dispose() {
    _walkedDebounce?.cancel();
    BleService.instance.nearbyUsers.removeListener(_onNearbyUsersChanged);
    BleService.instance.onUserLeft = null;
    super.dispose();
  }

  /// Called when a user is removed from the nearby list by the BLE cleanup timer.
  /// Immediately moves them from NEAR to WALKED (with data we already have)
  /// and schedules a full DB reload.
  void _onUserLeft(String leftUserId) {
    if (!mounted) return;
    setState(() {
      // Find the person in _nearPeople
      final idx = _nearPeople.indexWhere((p) => p.id == leftUserId);
      if (idx != -1) {
        final person = _nearPeople.removeAt(idx);
        // Add them to walked if not already there
        if (!_walkedPeople.any((p) => p.id == person.id)) {
          _walkedPeople.insert(
            0,
            NearbyPerson(
              id: person.id,
              name: person.name,
              avatar: person.avatar,
              bio: person.bio,
              lastSeenLocation: 'Crossed path',
              lastSeenTime: 'Just now',
              sharedInterests: person.sharedInterests,
              publicBoards: person.publicBoards,
            ),
          );
        }
      }
    });
    // Schedule a debounced DB reload to get proper timestamps
    _scheduleWalkedReload();
  }

  /// Debounces walked list reload — avoids multiple overlapping calls.
  void _scheduleWalkedReload({Duration delay = const Duration(seconds: 2)}) {
    _walkedDebounce?.cancel();
    _walkedDebounce = Timer(delay, () {
      if (mounted) _loadWalkedEncounters();
    });
  }

  Future<void> _onNearbyUsersChanged() async {
    final liveIds = BleService.instance.nearbyUsers.value;

    // Immediately remove users no longer nearby from the Near section
    if (mounted) {
      setState(() {
        _nearPeople.removeWhere((p) => !liveIds.contains(p.id));
        // Also remove from walked anyone who just came back near
        _walkedPeople.removeWhere((p) => liveIds.contains(p.id));
      });
    }

    // Find new IDs we need to fetch
    final existingIds = _nearPeople.map((p) => p.id).toSet();
    final newIds = liveIds.where((id) => !existingIds.contains(id)).toList();

    if (newIds.isEmpty) return;

    // Fetch in the background without blocking the UI
    final myUserId = _service.currentUser?.id;
    final myInterests = <String>[];
    if (myUserId != null) {
      try {
        final profile = await _service.getPerfil(myUserId);
        if (profile != null) {
          myInterests.addAll(List<String>.from(profile['intereses'] ?? []));
        }
      } catch (_) {}
    }

    for (final id in newIds) {
      if (!BleService.instance.nearbyUsers.value.contains(id)) continue;

      try {
        // Fetch profile
        final profileData = await _service.getPerfil(id);

        if (!BleService.instance.nearbyUsers.value.contains(id)) continue;

        if (profileData == null) {
          // Provide a fallback generic person if profile isn't found
          if (mounted) {
            setState(() {
              if (!_nearPeople.any((p) => p.id == id) &&
                  BleService.instance.nearbyUsers.value.contains(id)) {
                _nearPeople.add(
                  NearbyPerson(
                    id: id,
                    name: 'Nearby User',
                    avatar: '',
                    bio: 'Active on Collect',
                    lastSeenLocation: 'Nearby',
                    lastSeenTime: 'Just now',
                    sharedInterests: const [],
                    publicBoards: const [],
                  ),
                );
              }
            });
          }
          continue;
        }

        // Fetch boards
        List<Board> boards = [];
        try {
          final boardsData = await _service.getTablerosPublicos(id);
          boards = boardsData
              .map(
                (b) => Board(
                  id: b['id'] ?? '',
                  name: b['titulo'] ?? '',
                  description: b['descripcion'],
                  itemCount: 0,
                  coverImage: b['imagen_portada'],
                  color: '#1e1e32',
                  icon: 'compass',
                  isPublic: true,
                ),
              )
              .toList();
        } catch (_) {}

        if (!BleService.instance.nearbyUsers.value.contains(id)) continue;

        final theirInterests = List<String>.from(
          profileData['intereses'] ?? [],
        );
        final shared = theirInterests
            .where((i) => myInterests.contains(i))
            .toList();

        if (mounted) {
          setState(() {
            if (!_nearPeople.any((p) => p.id == id) &&
                BleService.instance.nearbyUsers.value.contains(id)) {
              _nearPeople.add(
                NearbyPerson(
                  id: id,
                  name:
                      profileData['nombre_completo'] ??
                      profileData['username'] ??
                      'Anonymous',
                  avatar: profileData['avatar_url'] ?? '',
                  bio: profileData['bio'] ?? '',
                  lastSeenLocation: 'Direct BLE Connection',
                  lastSeenTime: 'Just now',
                  sharedInterests: shared,
                  publicBoards: boards,
                ),
              );
            }
          });
        }
      } catch (e) {
        // Ignore failed fetches
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeNow = _nearPeople.toList();
    final earlier = _walkedPeople.toList();

    return Column(
      children: [
        // Header with decorative background
        Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(50),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Street',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 34, // h1 style
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'People who crossed your path',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 14, // h2 style
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _nearPeople.isEmpty
                              ? 'Scanning your surroundings...'
                              : '${activeNow.length} people nearby share your interests',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Only boards matching your interests are shown. Tap someone to see all their public boards.',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _initialLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _nearPeople.isEmpty && _walkedPeople.isEmpty
              ? _buildEmptyState()
              : ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.9, 1.0], // Fade only at bottom 10%
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activeNow.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12, left: 4),
                            child: Text(
                              'JUST NOW',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...activeNow.asMap().entries.map(
                            (entry) => AnimatedEntry(
                              index: entry.key,
                              child: _PersonCard(
                                person: entry.value,
                                onSelect: () =>
                                    widget.onPersonSelect(entry.value),
                              ),
                            ),
                          ),
                        ],
                        if (earlier.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12, left: 4),
                            child: Text(
                              'EARLIER',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...earlier.asMap().entries.map((entry) {
                            final p = entry.value;
                            return AnimatedEntry(
                              index: activeNow.length + entry.key,
                              child: Dismissible(
                                key: Key('walked_${p.id}'),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) async {
                                  setState(() {
                                    _walkedPeople.removeWhere(
                                      (e) => e.id == p.id,
                                    );
                                  });
                                  await _service.eliminarEncuentro(p.id);
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.destruct.withAlpha(50),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.destruct,
                                  ),
                                ),
                                child: _PersonCard(
                                  person: p,
                                  onSelect: () => widget.onPersonSelect(p),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border.withAlpha(50),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No one around yet',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Walk near someone with the app and you\'ll automatically discover their public boards.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _anim,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(77),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final NearbyPerson person;
  final VoidCallback onSelect;

  const _PersonCard({required this.person, required this.onSelect});

  IconData _boardIcon(String icon) {
    switch (icon) {
      case 'palette':
        return Icons.palette_outlined;
      case 'chef_hat':
        return Icons.restaurant_outlined;
      case 'mountain':
        return Icons.landscape_outlined;
      case 'building':
        return Icons.business_outlined;
      case 'book_open':
        return Icons.menu_book_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  List<Board> get _shownBoards {
    final matching = person.publicBoards
        .where(
          (b) => person.sharedInterests.any(
            (i) =>
                b.name.toLowerCase().contains(i) ||
                (b.description?.toLowerCase().contains(i) ?? false) ||
                b.icon == i,
          ),
        )
        .toList();
    return matching.isNotEmpty
        ? matching.take(1).toList()
        : person.publicBoards.take(1).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shownBoards = _shownBoards;
    final hiddenCount = person.publicBoards.length - shownBoards.length;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar, Name, Bio row
            Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: person.avatar.isNotEmpty
                          ? Image.network(
                              person.avatar,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        person.bio,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.mutedForeground,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location + time
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  person.lastSeenLocation,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  person.lastSeenTime,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Shared interests
            if (person.sharedInterests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'IN COMMON',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    ...person.sharedInterests.map(
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: Text(
                          i,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Boards
            if (shownBoards.isNotEmpty)
              Column(
                children: [
                  ...shownBoards.map(
                    (board) => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.border,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (board.coverImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                board.coverImage!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _BoardIconBox(icon: board.icon),
                              ),
                            )
                          else
                            _BoardIconBox(
                              icon: board.icon,
                              boardIcon: _boardIcon(board.icon),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  board.name,
                                  style: const TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${board.itemCount} items',
                                  style: const TextStyle(
                                    color: AppColors.secondaryForeground,
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
                  if (hiddenCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          '+$hiddenCount more public board${hiddenCount != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: AppColors.secondaryForeground),
    );
  }
}

class _BoardIconBox extends StatelessWidget {
  final String icon;
  final IconData? boardIcon;
  const _BoardIconBox({required this.icon, this.boardIcon});

  IconData get _icon {
    if (boardIcon != null) return boardIcon!;
    switch (icon) {
      case 'palette':
        return Icons.palette_outlined;
      case 'chef_hat':
        return Icons.restaurant_outlined;
      case 'mountain':
        return Icons.landscape_outlined;
      case 'building':
        return Icons.business_outlined;
      case 'book_open':
        return Icons.menu_book_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon, color: AppColors.primary, size: 18),
    );
  }
}
