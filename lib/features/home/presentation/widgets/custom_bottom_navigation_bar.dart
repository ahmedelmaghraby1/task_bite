import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/home/data/constant_data.dart';

/// Theme-aware bottom navigation with the task status tabs.
///
/// Selected items use the theme's primary container so the bar looks correct
/// in both light and dark mode (no hardcoded colors).
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.onTap,
    required this.index,
  });

  final int index;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: List.generate(
            navItemsNames.length,
            (currentIndex) => Expanded(
              child: _NavItem(
                icon: navItemsIcons[currentIndex],
                labelKey: navItemsNames[currentIndex],
                selected: currentIndex == index,
                onTap: () => onTap(currentIndex),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: labelKey.tr(context),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 18,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              labelKey.tr(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
