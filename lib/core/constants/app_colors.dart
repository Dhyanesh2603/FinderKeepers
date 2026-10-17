import 'package:flutter/material.dart';

/// Defines the cohesive color palette for Finders Keepers.
///
/// Design Language: Monochrome base, charcoal, off-white, muted green, and muted amber.
/// Avoids flashy saturated neons or harsh gradients in favor of a calm, premium aesthetic.
abstract class AppColors {
  // Monochrome Base
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF3F4F6);

  static const Color backgroundDark = Color(0xFF0F1012);
  static const Color surfaceDark = Color(0xFF16181B);
  static const Color surfaceVariantDark = Color(0xFF1F2227);

  // Charcoal Accents (Primary actions in light mode)
  static const Color charcoal = Color(0xFF14171A);
  static const Color charcoalLight = Color(0xFF2A2E35);

  // Muted Semantic Accents (Campus statuses)
  // Muted Green: Found / Verified / Reunited
  static const Color mutedGreen = Color(0xFF2E7D52);
  static const Color mutedGreenLight = Color(0xFFE8F5EE);

  // Muted Amber: Lost / Pending Verification / Action Needed
  static const Color mutedAmber = Color(0xFFC7771E);
  static const Color mutedAmberLight = Color(0xFFFDF4E7);

  // Muted Red: Cancelled / Rejected Claim
  static const Color mutedRed = Color(0xFFB83A3A);
  static const Color mutedRedLight = Color(0xFFFCEBEB);

  // Muted Blue: Claims / Discovery / Map Navigation
  static const Color mutedBlue = Color(0xFF2563EB);
  static const Color mutedBlueLight = Color(0xFFEFF6FF);

  // Text Hierarchy
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);

  // Subtle Borders and Dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF262A30);
}
