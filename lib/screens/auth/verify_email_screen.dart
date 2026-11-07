import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';
import '../../services/auth_repository.dart';
import '../../widgets/app_button.dart';

/// Blocks the app until the user clicks the link in the verification email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isSending = false;

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    try {
      final verified = await ref
          .read(authRepositoryProvider)
          .checkEmailVerified();
      if (verified) {
        // Re-read the user so the router sees the verified email.
        ref.invalidate(authStateProvider);
      } else {
        _showSnackBar(
          'Not verified yet. Check your inbox and spam folder.',
          isError: true,
        );
      }
    } catch (_) {
      _showSnackBar('Could not check. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isSending = true);
    try {
      await ref.read(authRepositoryProvider).sendVerificationEmail();
      _showSnackBar('Verification email sent.');
    } on AuthFailure catch (e) {
      _showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.resolved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).value?.email ?? 'your email';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a link to $email. Open it, then come back and '
                  'tap the button below.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: "I've verified my email",
                  icon: Icons.check,
                  isLoading: _isChecking,
                  onPressed: _checkVerified,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSending ? null : _resend,
                  child: const Text('Resend email'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
