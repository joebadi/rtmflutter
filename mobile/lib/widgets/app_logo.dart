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
    return Semantics(
      image: true,
      label: 'Compatible',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icon/compatible_mark.png',
            height: height,
            width: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              width: height,
              decoration: const BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: height * 0.58,
              ),
            ),
          ),
          if (showWordmark) ...[
            SizedBox(width: height * 0.28),
            ExcludeSemantics(
              child: Text(
                'Compatible',
                style: GoogleFonts.poppins(
                  color: color ?? AppTheme.textPrimary(context),
                  fontSize: height * 0.69,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
