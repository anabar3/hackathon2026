import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/ble_service.dart';

class DriftScreen extends StatefulWidget {
  final void Function(NearbyPerson) onPersonSelect;

  const DriftScreen({super.key, required this.onPersonSelect});

  @override
  State<DriftScreen> createState() => _DriftScreenState();
}

class _DriftScreenState extends State<DriftScreen> {
  final _service = SupabaseService();
  List<NearbyPerson> _people = [];

  @override
  void initState() {
    super.initState();
    BleService.instance.forceRefreshUI();
    BleService.instance.nearbyUsers.addListener(_onNearbyUsersChanged);
    _onNearbyUsersChanged(); // Initial sync
  }

  @override
  void dispose() {
    BleService.instance.nearbyUsers.removeListener(_onNearbyUsersChanged);
    super.dispose();
  }

  Future<void> _onNearbyUsersChanged() async {
    final liveIds = BleService.instance.nearbyUsers.value;

    // Immediately remove users no longer nearby
    if (mounted) {
      setState(() {
        _people.removeWhere((p) => !liveIds.contains(p.id));
      });
    }

    // Find new IDs we need to fetch
    final existingIds = _people.map((p) => p.id).toSet();
    final newIds = liveIds.where((id) => !existingIds.contains(id)).toList();

    if (newIds.isEmpty) return;

    // Fetch in the background without blocking the UI
    final myUserId = _service.currentUser?.id;
    final myInterests = <String>[];
    if (myUserId != null) {
      final profile = await _service.getPerfil(myUserId);
      if (profile != null) {
        myInterests.addAll(List<String>.from(profile['intereses'] ?? []));
      }
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
              if (!_people.any((p) => p.id == id) &&
                  BleService.instance.nearbyUsers.value.contains(id)) {
                _people.add(
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
            if (!_people.any((p) => p.id == id) &&
                BleService.instance.nearbyUsers.value.contains(id)) {
              _people.add(
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
    final activeNow = _people.toList();
    final earlier = <NearbyPerson>[];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        'Drift',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'People who crossed your path',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withAlpha(51),
                      ),
                    ),
                    child: const Icon(
                      Icons.waves,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Live pulse
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(38)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(),
                    const SizedBox(width: 8),
                    Text(
                      _people.isEmpty
                          ? 'Scanning for nearby people...'
                          : '${activeNow.length} ${activeNow.length == 1 ? 'person' : 'people'} nearby',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'People you cross paths with will appear here.\nBluetooth must be enabled.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _people.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeNow.isNotEmpty) ...[
                        const Text(
                          'JUST NOW',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...activeNow.map(
                          (p) => _PersonCard(
                            person: p,
                            onSelect: () => widget.onPersonSelect(p),
                          ),
                        ),
                      ],
                      if (earlier.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'EARLIER',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...earlier.map(
                          (p) => _PersonCard(
                            person: p,
                            onSelect: () => widget.onPersonSelect(p),
                          ),
                        ),
                      ],
                    ],
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
                Icons.bluetooth_searching,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No encounters yet',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Walk near someone with the app and you\'ll automatically connect via Bluetooth.',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        ? matching
        : person.publicBoards.take(1).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shownBoards = _shownBoards;
    final hiddenCount = person.publicBoards.length - shownBoards.length;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
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
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.card, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          person.bio,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
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
                    size: 18,
                  ),
                ],
              ),
            ),
            // Location + time
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: person.lastSeenLocation,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.access_time,
                    label: person.lastSeenTime,
                  ),
                ],
              ),
            ),
            // Shared interests
            if (person.sharedInterests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 6,
                  children: [
                    const Text(
                      'In common',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ...person.sharedInterests.map(
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(51),
                          ),
                        ),
                        child: Text(
                          i,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Boards
            if (shownBoards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  children: [
                    ...shownBoards.map(
                      (board) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withAlpha(154),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (board.coverImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  board.coverImage!,
                                  width: 40,
                                  height: 40,
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    board.name,
                                    style: const TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (board.description != null)
                                    Text(
                                      board.description!,
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hiddenCount > 0)
                      Text(
                        '+$hiddenCount more public board${hiddenCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: AppColors.mutedForeground),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.mutedForeground),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
