import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14303030),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            active: currentIndex == 0,
            onTap: () => onItemSelected?.call(0),
          ),
          _NavItem(
            icon: Icons.assignment_outlined,
            label: 'Services',
            active: currentIndex == 1,
            onTap: () => onItemSelected?.call(1),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            label: 'Community',
            active: currentIndex == 2,
            onTap: () => onItemSelected?.call(2),
          ),
          _NavItem(
            icon: Icons.payments_outlined,
            label: 'Payments',
            active: currentIndex == 3,
            onTap: () => onItemSelected?.call(3),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            active: currentIndex == 4,
            onTap: () => onItemSelected?.call(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1F85D5) : const Color(0xFF8F96A8);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
