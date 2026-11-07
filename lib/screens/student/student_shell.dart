import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

/// Student tabs with the bottom bar and the raised Report button.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          tooltip: 'Report an issue',
          // push (not go) so the back button returns to the current tab.
          onPressed: () => context.push(AppRoutes.reportIncident),
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              path: AppRoutes.home,
              currentPath: currentPath,
            ),
            _NavItem(
              icon: Icons.list_alt_outlined,
              label: 'Reports',
              path: AppRoutes.browse,
              currentPath: currentPath,
            ),
            // Empty space under the center Report button.
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.assignment_ind_outlined,
              label: 'My Reports',
              path: AppRoutes.myReports,
              currentPath: currentPath,
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              path: AppRoutes.profile,
              currentPath: currentPath,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == path;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
