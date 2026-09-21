// Junior Boy Boxing — App Theme Constants
// Auto-generated from design tokens

import 'package:flutter/material.dart';

class JBBColors {
  // Primary
  static const Color crimsonRed = Color(0xFFE50914);
  static const Color crimsonRedDark = Color(0xFFD32F2F);
  static const Color crimsonRedLight = Color(0xFFFF1744);
  static const Color redAccent = Color(0xFFFF0000);

  // Backgrounds
  static const Color bgPrimary = Color(0xFF0D0D0D);
  static const Color bgSecondary = Color(0xFF1A1A1A);
  static const Color bgCard = Color(0xFF181818);
  static const Color bgCardBorder = Color(0xFF2A2A2A);
  static const Color bgElevated = Color(0xFF222222);

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLightGray = Color(0xFFA0A0A0);
  static const Color textMediumGray = Color(0xFF808080);
  static const Color textDarkGray = Color(0xFF555555);
  static const Color textRed = Color(0xFFE50914);
  static const Color textGreen = Color(0xFF4CAF50);

  // Status
  static const Color statusAvailable = Color(0xFF4CAF50);
  static const Color statusLimited = Color(0xFFFF9800);
  static const Color statusFull = Color(0xFFE50914);

  // UI
  static const Color divider = Color(0xFF2A2A2A);
  static const Color navActive = Color(0xFFE50914);
  static const Color navInactive = Color(0xFF808080);
}

class JBBTextStyles {
  static const String _fontOswald = 'Oswald';
  static const String _fontRoboto = 'Roboto';

  static const TextStyle heroTitle = TextStyle(
    fontFamily: _fontOswald,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
    color: JBBColors.textWhite,
  );

  static const TextStyle heroTitleAccent = TextStyle(
    fontFamily: _fontOswald,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    letterSpacing: 2.0,
    color: JBBColors.crimsonRed,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: _fontOswald,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: JBBColors.textWhite,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _fontOswald,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: JBBColors.textWhite,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: JBBColors.textWhite,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: JBBColors.textLightGray,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: JBBColors.textLightGray,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: JBBColors.crimsonRed,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: _fontOswald,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 3.0,
    color: JBBColors.textLightGray,
  );

  static const TextStyle priceText = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: JBBColors.textWhite,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: JBBColors.textWhite,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: JBBColors.navInactive,
  );

  static const TextStyle welcomeName = TextStyle(
    fontFamily: _fontOswald,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: JBBColors.crimsonRed,
  );

  static const TextStyle availableSpots = TextStyle(
    fontFamily: _fontRoboto,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: JBBColors.statusAvailable,
  );
}

class JBBSpacing {
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double bottomNavHeight = 64.0;
}
