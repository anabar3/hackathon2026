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
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: Icons.grid_view_rounded,
              active: _isDashboard,
              onTap: () => onNavigate(Screen.dashboard),
            ),
            _NavItem(
              icon: Icons.wifi_tethering_rounded,
              active: _isDrift,
              onTap: () => onNavigate(Screen.drift),
            ),
            _NavItem(
              icon: Icons.inbox_rounded,
              active: _isInbox,
              onTap: () => onNavigate(Screen.inbox),
            ),
            _NavItem(
              icon: Icons.bookmark_border_rounded,
              active: _isLetters,
              onTap: () => onNavigate(Screen.letters),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              active: _isProfile,
              onTap: () => onNavigate(Screen.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF3F4F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF1E293B) : const Color(0xFF9CA3AF),
              size: 26,
            ),
            if (active)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
