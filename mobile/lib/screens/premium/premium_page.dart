import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// "Go Premium" — RTM's subscription upsell. Dark, premium presentation with a
/// benefits list, plan selector (weekly / monthly / annual), and a subscribe CTA.
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  int _selected = 1; // default: monthly

  static const List<_Plan> _plans = [
    _Plan(id: 'weekly', label: 'Weekly', price: 1500, period: 'week', perMonth: null, badge: null),
    _Plan(id: 'monthly', label: 'Monthly', price: 3800, period: 'month', perMonth: 3800, badge: 'POPULAR'),
    _Plan(id: 'annual', label: 'Annual', price: 38000, period: 'year', perMonth: 3167, badge: 'SAVE 17%'),
  ];

  static const List<(IconData, String, String)> _benefits = [
    (Icons.all_inclusive_rounded, 'Unlimited free chat', 'Message any match without spending diamonds'),
    (Icons.favorite_rounded, 'See who likes you', 'Skip the guesswork and match instantly'),
    (Icons.verified_rounded, 'Verified badge', 'Stand out as a genuine, trusted profile'),
    (Icons.bolt_rounded, 'Weekly profile boost', 'Be seen by far more people every week'),
    (Icons.replay_rounded, 'Unlimited rewinds', 'Undo an accidental pass anytime'),
    (Icons.videocam_rounded, 'Priority Live Dates', 'Early access to events and more rounds'),
    (Icons.block_rounded, 'Ad-free experience', 'Pure, uninterrupted dating'),
  ];

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  _hero(),
                  const SizedBox(height: 28),
                  _benefitsCard(),
                  const SizedBox(height: 24),
                  Text('Choose your plan',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  ...List.generate(_plans.length, (i) => _planCard(i)),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ----- Hero ------------------------------------------------------------

  Widget _hero() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final g = 0.3 + _glow.value * 0.3;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.accentGradient,
                boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(g), blurRadius: 40, spreadRadius: 4)],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
              child: Text('RTM Premium',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 8),
            Text('Date smarter. Get noticed. Match faster.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14, height: 1.5)),
          ],
        );
      },
    );
  }

  // ----- Benefits --------------------------------------------------------

  Widget _benefitsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _benefits.length; i++) ...[
            _benefitRow(_benefits[i]),
            if (i != _benefits.length - 1)
              Divider(color: Colors.white.withOpacity(0.05), height: 22),
          ],
        ],
      ),
    );
  }

  Widget _benefitRow((IconData, String, String) b) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(b.$1, color: AppTheme.accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.$2,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(b.$3,
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  // ----- Plans -----------------------------------------------------------

  Widget _planCard(int i) {
    final p = _plans[i];
    final selected = _selected == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.accent.withOpacity(0.18), AppTheme.darkSurface])
                : null,
            color: selected ? null : AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.accent : Colors.white.withOpacity(0.08),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: AppTheme.accent.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))]
                : null,
          ),
          child: Row(
            children: [
              // radio
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected ? AppTheme.accent : Colors.white30, width: 2),
                  color: selected ? AppTheme.accent : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Text(p.label,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    if (p.badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p.badge!,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₦${_money(p.price)}',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('/ ${p.period}',
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Footer (CTA) ----------------------------------------------------

  Widget _footer() {
    final p = _plans[_selected];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p.perMonth != null && p.id == 'annual')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Just ₦${_money(p.perMonth!)}/month, billed annually',
                  style: GoogleFonts.poppins(color: AppTheme.accentBright, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _subscribe,
                  child: Center(
                    child: Text('Continue · ₦${_money(p.price)}',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Auto-renews until cancelled. Manage anytime in your store settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _subscribe() {
    final p = _plans[_selected];
    // Premium billing isn't wired to a provider yet — surface a graceful notice
    // rather than silently doing nothing.
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.15),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.accent, size: 40),
            ),
            const SizedBox(height: 18),
            Text('Premium is launching soon',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'The ${p.label.toLowerCase()} plan (₦${_money(p.price)}) will be available to subscribe shortly. In the meantime you can use diamonds to chat and join Live Dates.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/wallet');
                },
                child: Text('Get diamonds instead',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Maybe later', style: GoogleFonts.poppins(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }

  String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Plan {
  const _Plan({
    required this.id,
    required this.label,
    required this.price,
    required this.period,
    required this.perMonth,
    required this.badge,
  });
  final String id;
  final String label;
  final int price;
  final String period;
  final int? perMonth;
  final String? badge;
}
