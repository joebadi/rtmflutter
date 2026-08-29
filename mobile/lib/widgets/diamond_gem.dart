import 'package:flutter/material.dart';

/// A faceted brilliant-cut diamond drawn with vector paths — crisp at any size,
/// no raster asset required. Used across the wallet as the diamond "coin".
///
/// [colors] tints the gem (defaults to a cool ice-blue); pass brand colors for
/// a warm gem. [shine] (0..1) sweeps a specular highlight for a sparkle effect.
class DiamondGem extends StatelessWidget {
  final double size;
  final List<Color>? colors;
  final double shine;

  const DiamondGem({super.key, this.size = 48, this.colors, this.shine = 0.5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiamondPainter(
          colors: colors ??
              const [Color(0xFF8FE3FF), Color(0xFF3AA9FF), Color(0xFF1C6FE0)],
          shine: shine,
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final List<Color> colors;
  final double shine;

  _DiamondPainter({required this.colors, required this.shine});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    // Key vertices (unit space, y down).
    final t1 = p(0.28, 0.07); // table top-left
    final t2 = p(0.72, 0.07); // table top-right
    final gl = p(0.05, 0.35); // girdle left
    final gr = p(0.95, 0.35); // girdle right
    final m1 = p(0.38, 0.35); // inner girdle left
    final m2 = p(0.62, 0.35); // inner girdle right
    final tip = p(0.50, 0.96); // pavilion tip

    final light = colors[0];
    final mid = colors[1];
    final dark = colors[2];

    void facet(List<Offset> pts, Color a, Color b) {
      final path = Path()..addPolygon(pts, true);
      final rect = path.getBounds();
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ).createShader(rect)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    }

    // Crown facets.
    facet([t1, t2, m2, m1], Color.lerp(light, Colors.white, 0.35)!, light); // table
    facet([t1, m1, gl], mid, dark); // crown left
    facet([t2, gr, m2], light, mid); // crown right

    // Pavilion facets (converge at the tip).
    facet([gl, m1, tip], dark, Color.lerp(dark, Colors.black, 0.25)!);
    facet([m1, m2, tip], mid, dark); // center pavilion
    facet([m2, gr, tip], Color.lerp(mid, dark, 0.5)!,
        Color.lerp(dark, Colors.black, 0.15)!);

    // Facet edges for definition.
    final edge = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..isAntiAlias = true;
    final edges = Path()
      ..addPolygon([t1, t2, gr, tip, gl], true)
      ..addPolygon([t1, m1, m2, t2], false)
      ..moveTo(m1.dx, m1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..moveTo(m2.dx, m2.dy)
      ..lineTo(tip.dx, tip.dy)
      ..moveTo(gl.dx, gl.dy)
      ..lineTo(m1.dx, m1.dy)
      ..moveTo(gr.dx, gr.dy)
      ..lineTo(m2.dx, m2.dy);
    canvas.drawPath(edges, edge);

    // Specular sparkle sweeping across the table.
    final sx = 0.30 + shine * 0.42;
    final spark = Path()
      ..addPolygon([p(sx, 0.10), p(sx + 0.06, 0.10), p(0.50, 0.33)], true);
    canvas.drawPath(
      spark,
      Paint()..color = Colors.white.withOpacity(0.55 * (1 - (shine - 0.5).abs())),
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter old) =>
      old.shine != shine || old.colors != colors;
}
