import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medi_theme.dart';

class MediShell extends StatelessWidget {
  const MediShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int i) {
    navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: MediColors.homeBackground,
      body: navigationShell,
      bottomNavigationBar: Material(
        color: MediColors.bottomNavBarBg,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 8, 6, 8 + bottom),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                selected: navigationShell.currentIndex == 0,
                icon: Icons.home_rounded,
                label: 'Басты бет',
                onTap: () => _onTap(0),
              ),
              _NavItem(
                selected: navigationShell.currentIndex == 1,
                icon: Icons.medication_rounded,
                label: 'Дәрілер',
                onTap: () => _onTap(1),
              ),
              _NavItem(
                selected: navigationShell.currentIndex == 2,
                icon: Icons.auto_awesome_rounded,
                label: 'Чат',
                onTap: () => _onTap(2),
              ),
              _NavItem(
                selected: navigationShell.currentIndex == 3,
                icon: Icons.insights_rounded,
                label: 'Шолу',
                onTap: () => _onTap(3),
              ),
              _NavItem(
                selected: navigationShell.currentIndex == 4,
                icon: Icons.person_rounded,
                label: 'Профиль',
                onTap: () => _onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 12 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? MediColors.bottomNavPill : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : MediColors.bottomNavIconInactive,
              size: selected ? 22 : 24,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
