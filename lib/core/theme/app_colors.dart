import 'package:flutter/material.dart';

/// Every color used in the app lives here (ALU brand palette).
/// Widgets should never hard-code hex values - use these tokens instead.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF012D6C); // ALU navy
  static const Color primaryDark = Color(0xFF001446); // banner gradient end
  static const Color primaryLight = Color(0xFFCEDEF5); // chips, icon tiles
  static const Color accent = Color(0xFFD00D2D); // ALU red, used sparingly
  static const Color accentDark = Color(0xFF971A42); // pressed accent

  // Neutrals
  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF102461);
  static const Color textSecondary = Color(0xFF5B6785);
  static const Color border = Color(0xFFE3E8F2);
  static const Color error = Color(0xFFB91C1C);

  // Status colors - keep these consistent everywhere in the app.
  static const Color submitted = Color(0xFFB45309);
  static const Color submittedBg = Color(0xFFFEF3C7);
  static const Color inProgress = Color(0xFF1D4ED8);
  static const Color inProgressBg = Color(0xFFDBEAFE);
  static const Color resolved = Color(0xFF15803D);
  static const Color resolvedBg = Color(0xFFDCFCE7);
}
