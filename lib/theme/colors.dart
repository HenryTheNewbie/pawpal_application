// lib/theme/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Background and UI Base
  static const Color background = Color(0xFFFFFBEE); // Soft cream

  // Primary Brand Color
  static const Color primary = Color(0xFFFEAB17); // Warm orange (from logo)

  // Text Colors
  static const Color textPrimary = Color(0xFF402E32);   // Deep brownish purple
  static const Color textSecondary = Color(0xCC402E32); // 80% opacity
  static const Color textDisabled = Color(0x55402E32);  // 33% opacity

  // Borders and Dividers
  static const Color border = Color(0xFFE0D7C8); // Optional light border color

  // Additional Accents (optional, to expand later)
  static const Color success = Color(0xFF4CAF50); // Standard green
  static const Color error = Color(0xFFF44336);   // Standard red
  static const Color warning = Color(0xFFFFC107); // Amber
}