import 'package:flutter/material.dart';

/// Every color used in the app lives here.
/// Widgets should never hard-code hex values - use these tokens instead.
class AppColors {
  // TODO(Mitchell): replace these placeholders with the real ALU brand
  // colors once you share the brand image.
  static const Color primary = Color(0xFF1A3A6B); // placeholder navy
  static const Color primaryDark = Color(0xFF0F2547); // placeholder dark navy
  static const Color accent = Color(0xFFE4572E); // placeholder orange-red
  static const Color background = Color(0xFFF5F7FA); // light neutral
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Used for borders, dividers and unselected icons.
  static const Color border = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFDC2626);

  // Status colors - keep these consistent everywhere in the app.
  static const Color submitted = Color(0xFFF59E0B);
  static const Color submittedBg = Color(0xFFFEF3C7);
  static const Color inProgress = Color(0xFF2563EB);
  static const Color inProgressBg = Color(0xFFDBEAFE);
  static const Color resolved = Color(0xFF16A34A);
  static const Color resolvedBg = Color(0xFFDCFCE7);
}
