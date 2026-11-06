import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/loading_view.dart';

/// Shown while we check whether the user is logged in and load their role.
///
/// The router moves the user away from here automatically once it knows
/// where they belong. If loading the profile fails, we show the error and
/// a sign out button so the user is never stuck.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: profile.hasError
              ? _ProfileError(
                  onSignOut: () => ref.read(authRepositoryProvider).signOut(),
                )
              : const LoadingView(message: 'Loading...'),
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'We could not load your profile.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
