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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              if (hasImage)
                Stack(
                  children: [
                    Image.network(
                      item.thumbnail!,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(height: 200, color: AppColors.surface),
                    ),
                    Container(
                      height: 280,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xDD0F0F17)],
                        ),
                      ),
                    ),
                    if (item.type == ContentType.video)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(230),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  height: 160,
                  color: AppColors.surface,
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _typeIcon(),
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _typeIcon(),
                                color: AppColors.primary,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.type.name,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                board.isPublic
                                    ? Icons.public
                                    : Icons.lock_outline,
                                size: 11,
                                color: AppColors.mutedForeground,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                board.isPublic ? 'Public' : 'Private',
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
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    if (item.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'by ${item.author}',
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (item.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        item.description!,
                        style: const TextStyle(
                          color: AppColors.secondaryForeground,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Metadata
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Added ${item.createdAt}',
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(icon: Icons.folder_outlined, label: board.name),
                    if (item.duration != null) ...[
                      const SizedBox(height: 10),
                      _MetaRow(icon: Icons.access_time, label: item.duration!),
                    ],
                    if (item.size != null) ...[
                      const SizedBox(height: 10),
                      _MetaRow(
                        icon: Icons.insert_drive_file_outlined,
                        label: item.size!,
                      ),
                    ],
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Icon(
                            Icons.tag,
                            size: 16,
                            color: AppColors.mutedForeground,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TAGS',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: AppColors.secondaryForeground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (item.url != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text(
                            'Open Link',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                    if (item.type == ContentType.audio) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: 0.33,
                                    backgroundColor: AppColors.border,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '15:23',
                                        style: TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        item.duration ?? '--',
                                        style: const TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BlurBtn(icon: Icons.arrow_back, onTap: onBack),
                  Row(
                    children: [
                      _BlurBtn(
                        icon: item.saved
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        color: item.saved
                            ? AppColors.primary
                            : AppColors.foreground,
                        onTap: () => onToggleSaved(item.id),
                      ),
                      const SizedBox(width: 8),
                      _BlurBtn(icon: Icons.share_outlined, onTap: () {}),
                      const SizedBox(width: 8),
                      _BlurBtn(icon: Icons.more_horiz, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _BlurBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _BlurBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppColors.foreground, size: 18),
      ),
    );
  }
}
