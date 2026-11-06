import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A labelled text field with the app's styling.
///
/// For password fields, set [isPassword] to get a show/hide eye button.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Passwords start hidden; the eye button toggles this.
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          obscureText: widget.isPassword && _obscureText,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, color: AppColors.textSecondary),
            suffixIcon: widget.isPassword ? _buildEyeButton() : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEyeButton() {
    return IconButton(
      tooltip: _obscureText ? 'Show password' : 'Hide password',
      icon: Icon(
        _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textSecondary,
      ),
      onPressed: () => setState(() => _obscureText = !_obscureText),
    );
  }
}
