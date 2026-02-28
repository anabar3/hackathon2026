import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const ContentCard({super.key, required this.item, required this.onTap});

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

  String _typeLabel() => item.type.name;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.thumbnail != null &&
        (item.type == ContentType.image ||
            item.type == ContentType.video ||
            item.type == ContentType.link);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Stack(
                children: [
                  Image.network(
                    item.thumbnail!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.surface,
                      child: Center(
                        child: Icon(_typeIcon(), color: AppColors.primary),
                      ),
                    ),
                  ),
                  if (item.type == ContentType.video)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(230),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (item.saved)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bookmark,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 72,
                color: AppColors.surface,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _typeIcon(),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _typeLabel(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.author != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.author!,
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.duration != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.duration!,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
