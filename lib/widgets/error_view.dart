import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Shown when loading data fails, with a "Try again" button.
///
/// In debug builds it also shows the technical error. That matters for
/// Firestore "missing index" errors, whose message contains the link
/// that creates the index.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.error,
  });

  final String message;
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall,
            ),
            if (kDebugMode && error != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                '$error',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
