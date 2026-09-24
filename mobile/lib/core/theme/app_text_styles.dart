import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle title = GoogleFonts.oswald(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
  static TextStyle section = GoogleFonts.oswald(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );
  static TextStyle label = GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: const Color(0xFFE50914),
  );
}
