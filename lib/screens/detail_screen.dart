import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onBack;
  final void Function(String) onToggleSaved;

  const DetailScreen({
    super.key,
    required this.item,
    required this.onBack,
    required this.onToggleSaved,
  });

  IconData _typeIcon() {
    switch (item.type) {
      case ContentType.video:
        return Icons.play_circle_outline;
      case ContentType.link:
        return Icons.link;
      case ContentType.audio:
        return Icons.headphones;
      case ContentType.note:
        return Icons.sticky_note_2_outlined;
      case ContentType.document:
        return Icons.description_outlined;
      case ContentType.file:
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = boards.firstWhere(
      (b) => b.id == item.boardId,
      orElse: () => boards.first,
    );
    final hasImage =
        item.thumbnail != null &&
        (item.type == ContentType.image ||
            item.type == ContentType.video ||
            item.type == ContentType.link);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Image Area
                Container(
                  color: AppColors.secondary,
                  height: 320,
                  width: double.infinity,
                  child: hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  _typeIcon(),
                                  color: AppColors.primary,
                                  size: 64,
                                ),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                  colors: [
                                    Color(0x88352F20),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            if (item.type == ContentType.video)
                              Positioned.fill(
                                child: Center(
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.card,
                                        width: 4,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: Icon(
                            _typeIcon(),
                            color: AppColors.primary,
                            size: 64,
                          ),
                        ),
                ),

                // Content Panel overlapping the image
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _typeIcon(),
                                      color: AppColors.primaryForeground,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.type.name,
                                      style: const TextStyle(
                                        color: AppColors.primaryForeground,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      board.isPublic
                                          ? Icons.public
                                          : Icons.lock_outline,
                                      size: 14,
                                      color: AppColors.mutedForeground,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      board.isPublic ? 'Public' : 'Private',
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          if (item.author != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'by ${item.author}',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Description Box
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 3,
                                ),
                              ),
                              child: Text(
                                item.description!,
                                style: const TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 15,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Metadata Table
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.border,
                                width: 3,
                              ),
                            ),
                            child: Column(
                              children: [
                                _MetaRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Added ${item.createdAt}',
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                    color: AppColors.border,
                                    thickness: 2,
                                    height: 2,
                                  ),
                                ),
                                _MetaRow(
                                  icon: Icons.folder_rounded,
                                  label: board.name,
                                ),
                                if (item.duration != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(
                                      color: AppColors.border,
                                      thickness: 2,
                                      height: 2,
                                    ),
                                  ),
                                  _MetaRow(
                                    icon: Icons.access_time_rounded,
                                    label: item.duration!,
                                  ),
                                ],
                                if (item.size != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(
                                      color: AppColors.border,
                                      thickness: 2,
                                      height: 2,
                                    ),
                                  ),
                                  _MetaRow(
                                    icon: Icons.insert_drive_file_rounded,
                                    label: item.size!,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (item.tags.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Row(
                              children: const [
                                Icon(
                                  Icons.sell_rounded,
                                  size: 18,
                                  color: AppColors.mutedForeground,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'TAGS',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: item.tags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],

                          if (item.url != null) ...[
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Open Link',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SolidBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                    Row(
                      children: [
                        _SolidBtn(
                          icon: item.saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: item.saved
                              ? AppColors.accent
                              : AppColors.foreground,
                          onTap: () => onToggleSaved(item.id),
                        ),
                        const SizedBox(width: 8),
                        _SolidBtn(
                          icon: Icons.library_add_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Guardando en Inbox...')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _SolidBtn(icon: Icons.share_rounded, onTap: () {}),
                        const SizedBox(width: 8),
                        _SolidBtn(icon: Icons.more_horiz_rounded, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mutedForeground),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SolidBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _SolidBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: color ?? AppColors.foreground, size: 20),
      ),
    );
  }
}
