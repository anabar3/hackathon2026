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
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                icon: Icons.wifi_tethering_rounded,
                label: 'Street',
                active: _isDrift,
                onTap: () => onNavigate(Screen.drift),
              ),
              // Center FAB (Sage green floating + button)
              GestureDetector(
                onTap: _isInbox ? onAddInbox : onAdd,
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.border.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: AppColors.foreground,
                        size: 28,
                      ),
                      // Red notification dot
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.destruct,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.bookmark_border_rounded,
                label: 'Letters',
                active: _isInbox,
                onTap: () => onNavigate(Screen.inbox),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : AppColors.mutedForeground,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.mutedForeground,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
