import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PersonBoardsScreen extends StatelessWidget {
  final NearbyPerson person;
  final VoidCallback onBack;

  const PersonBoardsScreen({
    super.key,
    required this.person,
    required this.onBack,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
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
                  const SizedBox(width: 10),
                  const Text(
                    'Back to Drift',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Profile
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      person.avatar,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.mutedForeground,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          person.bio,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: person.lastSeenLocation,
                            ),
                            const SizedBox(width: 10),
                            _InfoChip(
                              icon: Icons.access_time,
                              label: person.lastSeenTime,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Shared interests
              Wrap(
                spacing: 8,
                children: person.sharedInterests
                    .map(
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PUBLIC BOARDS (${person.publicBoards.length})',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ...person.publicBoards.map(
                  (board) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (board.coverImage != null)
                          Stack(
                            children: [
                              Image.network(
                                board.coverImage!,
                                height: 96,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 80,
                                  color: AppColors.surface,
                                ),
                              ),
                              Container(
                                height: 96,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xCC1E1E32),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _boardIcon(board.icon),
                                  color: AppColors.primary,
                                  size: 18,
                                ),
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${board.itemCount} items',
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (board.description != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Text(
                              board.description!,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                                height: 1.4,
                              ),
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
        const SizedBox(width: 3),
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
