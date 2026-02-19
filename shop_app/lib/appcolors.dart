import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryOrange = Color(0xFFFB923C);
  static const Color primaryRed = Color(0xFFEF4444);
  static const Color primaryBlack = Color(0xFF111827);

  // Background Colors
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFFAFAFA);
  static const Color bgOrangeLight = Color(0xFFFFF7ED);
  static const Color bgRedLight = Color(0xFFFEF2F2);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF111827);

  // Input Colors
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputFocus = Color(0xFF111827);
  static const Color inputPlaceholder = Color(0xFF9CA3AF);

  // Button Colors
  static const Color btnPrimary = Color(0xFF111827);
  static const Color btnSecondary = Color(0xFFFFFFFF);
  static const Color btnHover = Color(0xFF1F2937);

  // Icon Colors
  static const Color iconLight = Color(0xFFD1D5DB);
  static const Color iconMedium = Color(0xFF9CA3AF);
  static const Color iconDark = Color(0xFF6B7280);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}