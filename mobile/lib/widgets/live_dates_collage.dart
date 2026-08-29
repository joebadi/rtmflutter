import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Animated dating-collage empty state for the Live Dates lobby.
///
/// Shown when no events are scheduled. Three columns of photo tiles drift
/// vertically at different speeds behind a dark gradient scrim, with a hero
/// headline + CTA — evoking a lively dating community waiting to meet.
///
/// PHOTOS: drop curated images into `mobile/assets/collage/` named
/// `1.jpg` … `12.jpg`. Until then, warm stylised gradient tiles render in
/// their place so the screen always looks intentional. For "Ready to Marry"
/// the photos should celebrate African connection across ages — youthful
/// dates, couples, friends, and elders — warm, joyful, real.
class LiveDatesCollage extends StatefulWidget {
  const LiveDatesCollage({
    super.key,
    required this.onRefresh,
    this.title = 'Meet your match,\nface to face',
    this.subtitle =
        'Speed-dating & blind-date events with real people — live video and audio rounds. New events drop regularly.',
  });

  /// Called when the user taps the primary CTA (re-checks for events).
  final Future<void> Function() onRefresh;
  final String title;
  final String subtitle;

  @override
  State<LiveDatesCollage> createState() => _LiveDatesCollageState();
}

class _LiveDatesCollageState extends State<LiveDatesCollage>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _intro;
  bool _busy = false;

  // Each column gets its own tile heights so totals differ → the columns
  // drift at visually distinct rates from a single controller (no sync).
  late final List<_Column> _columns;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 44),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    final rnd = Random(7);
    int imgIndex = 1;
    _columns = List.generate(3, (col) {
      final tiles = <_TileSpec>[];
      // 5–6 tiles per column with varied heights for a masonry feel.
      final count = col == 1 ? 6 : 5;
      for (var i = 0; i < count; i++) {
        final h = 132.0 + rnd.nextInt(5) * 22; // 132..220
        tiles.add(_TileSpec(asset: imgIndex, height: h));
        imgIndex = imgIndex >= 12 ? 1 : imgIndex + 1;
      }
      return _Column(tiles: tiles, down: col == 1);
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ----- Drifting collage -----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _columns.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _DriftColumn(
                      column: _columns[i],
                      controller: _drift,
                      phase: i / _columns.length,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ----- Top fade (blends into the screen header) -----
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.darkBg, AppTheme.darkBg.withOpacity(0)],
              ),
            ),
          ),
        ),

        // ----- Bottom scrim + hero content -----
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.30, 0.58, 1.0],
                colors: [
                  AppTheme.darkBg.withOpacity(0),
                  AppTheme.darkBg.withOpacity(0.82),
                  AppTheme.darkBg,
                ],
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_intro.value);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 28),
                  child: child,
                ),
              );
            },
            child: _hero(context),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseBadge(),
          const SizedBox(height: 18),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _handleRefresh,
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Check for events',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => _showHowItWorks(context),
            child: Text(
              'How Live Dates work',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'How Live Dates work',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _step(
              icon: Icons.event_available_rounded,
              title: 'Book a spot',
              body:
                  'Reserve your place in a scheduled Speed-Dating (video) or Blind-Date (audio) event.',
            ),
            _step(
              icon: Icons.bolt_rounded,
              title: 'Go live in rounds',
              body:
                  'When the event starts, you’re paired one-on-one for short timed rounds, then rotated to your next match.',
            ),
            _step(
              icon: Icons.favorite_rounded,
              title: 'Signal interest',
              body:
                  'After each round, privately mark Interested or Pass and rate the vibe. No awkwardness.',
            ),
            _step(
              icon: Icons.chat_bubble_rounded,
              title: 'Match & chat free',
              body:
                  'If you both said yes, it’s a match — your chat unlocks free so you can keep the spark going.',
              last: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step({
    required IconData icon,
    required String title,
    required String body,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 24 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Drifting column
// --------------------------------------------------------------------------

class _Column {
  _Column({required this.tiles, required this.down})
      : totalHeight = tiles.fold<double>(0, (s, t) => s + t.height + _gap);
  final List<_TileSpec> tiles;
  final bool down; // drift direction
  final double totalHeight;
  static const double _gap = 12;
}

class _TileSpec {
  const _TileSpec({required this.asset, required this.height});
  final int asset; // 1..12 → assets/collage/<n>.jpg
  final double height;
}

class _DriftColumn extends StatelessWidget {
  const _DriftColumn({
    required this.column,
    required this.controller,
    required this.phase,
  });

  final _Column column;
  final AnimationController controller;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final content = OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          for (final t in column.tiles) ...[
            _CollageTile(spec: t),
            const SizedBox(height: _Column._gap),
          ],
        ],
      ),
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final p = (controller.value + phase) % 1.0;
          final shift = p * column.totalHeight;
          final base = column.down ? shift - column.totalHeight : -shift;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(offset: Offset(0, base), child: content),
              Transform.translate(
                offset: Offset(0, base + column.totalHeight),
                child: content,
              ),
            ],
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Tile (asset photo, with a stylised warm placeholder fallback)
// --------------------------------------------------------------------------

class _CollageTile extends StatelessWidget {
  const _CollageTile({required this.spec});
  final _TileSpec spec;

  // Warm gradient palette + a friendly icon, so missing photos still read as
  // a vibrant dating collage rather than broken images.
  static const List<List<Color>> _palettes = [
    [Color(0xFFFF7043), Color(0xFFE64A19)],
    [Color(0xFFE91E63), Color(0xFFAD1457)],
    [Color(0xFFFF8A65), Color(0xFFF4511E)],
    [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
    [Color(0xFFFFA726), Color(0xFFEF6C00)],
    [Color(0xFFEC407A), Color(0xFFC2185B)],
  ];
  static const List<IconData> _icons = [
    Icons.favorite_rounded,
    Icons.people_alt_rounded,
    Icons.local_florist_rounded,
    Icons.celebration_rounded,
    Icons.emoji_emotions_rounded,
    Icons.volunteer_activism_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: spec.height,
        width: double.infinity,
        child: Image.asset(
          'assets/collage/${spec.asset}.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    final palette = _palettes[spec.asset % _palettes.length];
    final icon = _icons[spec.asset % _icons.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 30),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Pulsing "LIVE DATES" badge
// --------------------------------------------------------------------------

class _PulseBadge extends StatefulWidget {
  const _PulseBadge();

  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final glow = 0.4 + _c.value * 0.6;
              return Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(glow),
                      blurRadius: 8,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 9),
          Text(
            'LIVE DATES',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
