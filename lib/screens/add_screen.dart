import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddScreen extends StatefulWidget {
  final VoidCallback onClose;
  const AddScreen({super.key, required this.onClose});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

enum _InboxPhase { idle, processing, done }

class _AddScreenState extends State<AddScreen>
    with SingleTickerProviderStateMixin {
  _InboxPhase _phase = _InboxPhase.idle;
  int _steps = 0;
  bool _isEditing = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _simulateProcessing() async {
    setState(() {
      _phase = _InboxPhase.processing;
      _steps = 0;
    });
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(Duration(milliseconds: i == 1 ? 400 : 800));
      if (mounted) setState(() => _steps = i);
    }
    if (mounted) setState(() => _phase = _InboxPhase.done);
  }

  void _reset() => setState(() {
    _phase = _InboxPhase.idle;
    _steps = 0;
    _isEditing = false;
  });

  Widget _stepRow(int step, String label) {
    final done = _steps > step;
    final active = _steps == step;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (done)
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 11),
            )
          else if (active)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: done || active
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static const _quickActions = [
    (Icons.camera_alt_outlined, 'Camera'),
    (Icons.photo_outlined, 'Photos'),
    (Icons.link, 'Link'),
    (Icons.mic_outlined, 'Voice'),
    (Icons.upload_file_outlined, 'File'),
  ];

  static const _recentDrops = [
    ('IMG_2847.jpg', '2 min ago', 'Travel Inspo'),
    ('recipe-link.url', '15 min ago', 'Recipes'),
    ('voice-memo-03.m4a', '1h ago', 'Reading List'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
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
              const Expanded(
                child: Center(
                  child: Text(
                    'Inbox',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_phase == _InboxPhase.idle) return _buildIdle();
    if (_phase == _InboxPhase.processing) return _buildProcessing();
    return _buildDone();
  }

  Widget _buildIdle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drop zone
        GestureDetector(
          onTap: _simulateProcessing,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withAlpha(77),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Drop anything here',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Photos, links, files, voice memos...\nAI will name, describe, tag, and sort it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Quick capture
        const Text(
          'QUICK CAPTURE',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _quickActions.map((action) {
            final isFirst = action == _quickActions.first;
            return Expanded(
              child: GestureDetector(
                onTap: _simulateProcessing,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isFirst
                        ? AppColors.primary.withAlpha(26)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFirst
                          ? AppColors.primary.withAlpha(64)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        action.$1,
                        color: isFirst
                            ? AppColors.primary
                            : AppColors.foreground,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.$2,
                        style: TextStyle(
                          color: isFirst
                              ? AppColors.primary
                              : AppColors.foreground,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Paste link
        const Text(
          'PASTE LINK',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.link,
                      color: AppColors.mutedForeground,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'https://...',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _simulateProcessing,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Recent
        const Text(
          'RECENT',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ..._recentDrops.map(
          (drop) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(154),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withAlpha(77)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drop.$1,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${drop.$2} · ${drop.$3}',
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
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(38),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 32,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Processing...',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'AI is analyzing your content',
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
        ),
        const SizedBox(height: 32),
        ...[
          (1, 'Content type detected'),
          (2, 'Title and description generated'),
          (3, 'Tags assigned and board matched'),
          (4, 'Sorted to board'),
        ].map((s) => _stepRow(s.$1, s.$2)),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        // Success header
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sorted by AI',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Review and confirm, or edit the details',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Preview card
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&q=80',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 120, color: AppColors.surface),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _isEditing ? _buildEditForm() : _buildPreview(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!_isEditing)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Discard',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'IMAGE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: AppColors.mutedForeground,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Santorini Blue Domes',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Iconic white-washed buildings with blue domes overlooking the Aegean Sea at sunset.',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['greece', 'architecture', 'sunset', 'islands']
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withAlpha(38)),
          ),
          child: const Row(
            children: [
              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Travel Inspo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TITLE',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'Santorini Blue Domes',
            style: TextStyle(color: AppColors.foreground, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'BOARD',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Travel Inspo',
                style: TextStyle(color: AppColors.foreground, fontSize: 13),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.mutedForeground,
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _isEditing = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Done Editing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
