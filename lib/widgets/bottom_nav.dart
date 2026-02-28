import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final Screen activeScreen;
  final void Function(Screen) onNavigate;

  const BottomNav({
    super.key,
    required this.activeScreen,
    required this.onNavigate,
  });

  bool get _isDashboard => activeScreen == Screen.dashboard;
  bool get _isDrift =>
      activeScreen == Screen.drift || activeScreen == Screen.personBoards;
  bool get _isInbox => activeScreen == Screen.inbox;
  bool get _isLetters => activeScreen == Screen.letters;
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              _NavItem(
                icon: Icons.inbox_rounded,
                label: 'Inbox',
                active: _isInbox,
                onTap: () => onNavigate(Screen.inbox),
              ),
              _NavItem(
                icon: Icons.bookmark_border_rounded,
                label: 'Letters',
                active: _isLetters,
                onTap: () => onNavigate(Screen.letters),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
