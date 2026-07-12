import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFBF1B2C);
  static const Color primaryDark = Color(0xFF8B0000);
  static const Color primaryLight = Color(0xFFFF5A76);

  // Background Colors
  static const Color bgLight = Color(0xFFF4F7FB);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF1A1A2E);
  static const Color bgDarker = Color(0xFF0F0F1A);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFCCCCCC);

  // Accent Colors
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentPurple = Color(0xFF7B2FBE);

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF333355);

  // Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);

  // Bottom Nav
  static const Color navBg = Color(0xFFF9FBFF);
  static const Color navBgDark = Color(0xFF16213E);
  static const Color navActive = Color(0xFFBF1B2C);
  static const Color navInactive = Color(0xFF9E9E9E);

  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEB4B6E), Color(0xFFBF1B2C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
