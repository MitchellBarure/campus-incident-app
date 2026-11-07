import 'package:flutter/material.dart';

/// Full-width button. Shows a spinner and ignores taps while [isLoading].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (isLoading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(width: 8), Text(label)],
      );
    } else {
      child = Text(label);
    }

    return FilledButton(onPressed: isLoading ? null : onPressed, child: child);
  }
}
