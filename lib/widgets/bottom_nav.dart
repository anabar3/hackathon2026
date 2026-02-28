import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final Screen activeScreen;
  final void Function(Screen) onNavigate;
  final VoidCallback onAdd;
  final VoidCallback onAddInbox;

  const BottomNav({
    super.key,
    required this.activeScreen,
    required this.onNavigate,
    required this.onAdd,
    required this.onAddInbox,
  });

  bool get _isDashboard => activeScreen == Screen.dashboard;
  bool get _isDrift =>
      activeScreen == Screen.drift || activeScreen == Screen.personBoards;
  bool get _isInbox => activeScreen == Screen.inbox;
  bool get _isProfile => activeScreen == Screen.profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withAlpha(242),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Home',
                active: _isDashboard,
                onTap: () => onNavigate(Screen.dashboard),
              ),
              _NavItem(
                icon: Icons.inbox_outlined,
                label: 'Inbox',
                active: _isInbox,
                onTap: () => onNavigate(Screen.inbox),
              ),
              _NavItem(
                icon: Icons.waves_rounded,
                label: 'Drift',
                active: _isDrift,
                onTap: () => onNavigate(Screen.drift),
              ),
              // Center FAB
              GestureDetector(
                onTap: _isInbox ? onAddInbox : onAdd,
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                active: _isProfile,
                onTap: () => onNavigate(Screen.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.mutedForeground;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
