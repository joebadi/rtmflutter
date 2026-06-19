import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// The "Compatible" brand mark — app icon + wordmark. Theme-aware.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 26,
    this.showWordmark = true,
    this.color,
  });

  /// Logo glyph height; the wordmark scales from it.
  final double height;
  final bool showWordmark;

  /// Override the wordmark color (defaults to theme primary text).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height * 0.28),
          child: Image.asset(
            'assets/icon/app_icon.png',
            height: height,
            width: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              width: height,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(height * 0.28),
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: height * 0.34),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: height * 0.72,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              children: [
                TextSpan(
                  text: 'Compat',
                  style: TextStyle(color: color ?? AppTheme.textPrimary(context)),
                ),
                const TextSpan(
                  text: 'ible',
                  style: TextStyle(color: AppTheme.accent),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
