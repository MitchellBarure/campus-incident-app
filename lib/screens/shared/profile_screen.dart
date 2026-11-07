import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/incident_providers.dart';
import '../../services/seed_data.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      // .when picks a widget for each state: data, loading, or error.
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: 'Could not load your profile.',
          error: error,
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
        data: (user) {
          // Briefly null while signing out.
          if (user == null) return const LoadingView();
          return _ProfileContent(
            user: user,
            onSignOut: () => ref.read(authRepositoryProvider).signOut(),
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initial = user.name.isEmpty ? '?' : user.name[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initial,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        // Hidden in release builds.
        if (kDebugMode) ...[
          const SizedBox(height: 32),
          _SeedDataButton(user: user),
        ],
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isStaff = role == UserRole.staff;
    final color = isStaff ? AppColors.accent : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Debug only: adds 8 sample reports.
class _SeedDataButton extends ConsumerStatefulWidget {
  const _SeedDataButton({required this.user});

  final AppUser user;

  @override
  ConsumerState<_SeedDataButton> createState() => _SeedDataButtonState();
}

class _SeedDataButtonState extends ConsumerState<_SeedDataButton> {
  bool _isSeeding = false;

  Future<void> _seed() async {
    setState(() => _isSeeding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await seedSampleIncidents(
        ref.read(incidentRepositoryProvider),
        widget.user,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Added $count sample reports')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not add sample reports: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Developer tools (debug builds only)',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isSeeding ? null : _seed,
          icon: _isSeeding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.dataset_outlined),
          label: const Text('Add 8 sample reports'),
        ),
      ],
    );
  }
}
