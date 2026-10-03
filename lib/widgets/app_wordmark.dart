import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Text wordmark: "Family" in gold over a spaced-out "CIRCLE" tagline.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Family',
          style: GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
            height: 1,
          ),
        ),
        Text(
          'CIRCLE',
          style: GoogleFonts.poppins(
            fontSize: fontSize * 0.26,
            fontWeight: FontWeight.w600,
            letterSpacing: 6,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
