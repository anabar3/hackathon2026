import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;
  final VoidCallback? onImport;
  final VoidCallback? onDownload;

  const ContentCard({super.key, required this.item, required this.onTap, this.onImport, this.onDownload});

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
        item.type != ContentType.note &&
        item.thumbnail != null &&
        (item.type == ContentType.image ||
            item.type == ContentType.video ||
            item.type == ContentType.link);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.border, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(21),
                    ),
                    child: Image.network(
                      item.thumbnail!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 170,
                        color: AppColors.surface,
                        child: Center(
                          child: Icon(_typeIcon(), color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (item.type == ContentType.video)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(230),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  if (item.saved)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.card.withAlpha(210),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bookmark,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card.withAlpha(210),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _typeLabel(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.author != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.author!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _typeLabel(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'por ${item.author!}',
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Text(
                  item.description!,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (onImport != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: GestureDetector(
                  onTap: onImport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Import to Inbox',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (onDownload != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: GestureDetector(
                  onTap: onDownload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.type == ContentType.note
                              ? Icons.copy_rounded
                              : item.type == ContentType.link
                                  ? Icons.open_in_new_rounded
                                  : Icons.download_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.type == ContentType.note
                              ? 'Copiar texto'
                              : item.type == ContentType.link
                                  ? 'Abrir enlace'
                                  : 'Descargar',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
