import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/payment_config.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/diamond_gem.dart';
import 'paystack_checkout_page.dart';

/// The diamonds store — an animated gem hero, what diamonds unlock, glowing
/// top-up tiers, and an in-app secure checkout. Bold, premium, game-like.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  String? _busyId; // package being purchased (tap feedback)

  // Ice-blue gem palette for the store centrepiece.
  static const _gem = [Color(0xFFBDEBFF), Color(0xFF49B6FF), Color(0xFF1E74E0)];

  // Fallback catalogue shown only until the backend packages load.
  static const List<Map<String, dynamic>> _fallbackPackages = [
    {'id': 'dp_100', 'diamonds': 100, 'price': 1500, 'bonus': 0, 'popular': false},
    {'id': 'dp_500', 'diamonds': 500, 'price': 6500, 'bonus': 50, 'popular': true},
    {'id': 'dp_1000', 'diamonds': 1000, 'price': 12000, 'bonus': 150, 'popular': false},
    {'id': 'dp_2500', 'diamonds': 2500, 'price': 28000, 'bonus': 500, 'popular': false},
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final balance = wallet.balance;
    final packages =
        wallet.packages.isNotEmpty ? wallet.packages : _fallbackPackages;
    final bestId = _bestValueId(packages);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          _aurora(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.darkSurface,
                    onRefresh: () => context.read<WalletProvider>().refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
                      children: [
                        _balanceHero(balance),
                        const SizedBox(height: 30),
                        _sectionTitle('What diamonds unlock'),
                        const SizedBox(height: 14),
                        _perksRow(),
                        const SizedBox(height: 30),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _sectionTitle('Choose your pack')),
                            Text('Pay once · no subscription',
                                style: GoogleFonts.poppins(
                                    color: Colors.white38, fontSize: 11.5)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.72,
                          children: List.generate(
                            packages.length,
                            (i) => _packageCard(
                                packages[i] as Map, bestId),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _trustRow(),
                        const SizedBox(height: 16),
                        _historyButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- Ambient background ---------------------------------------------

  Widget _aurora() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.75),
                radius: 1.1 + t * 0.15,
                colors: [
                  AppTheme.accent.withOpacity(0.18 + t * 0.06),
                  AppTheme.darkBg.withOpacity(0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----- Header ---------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            child: Text('Diamonds',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19)),
          ),
          IconButton(
            icon:
                const Icon(Icons.receipt_long_rounded, color: Colors.white70),
            onPressed: _showTransactions,
          ),
        ],
      ),
    );
  }

  // ----- Balance hero ---------------------------------------------------

  Widget _balanceHero(int balance) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141821), Color(0xFF0D0D10)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF49B6FF).withOpacity(0.10 + t * 0.10),
                  blurRadius: 40,
                  offset: const Offset(0, 16)),
            ],
          ),
          child: Column(
            children: [
              // Glowing gem.
              SizedBox(
                height: 108,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF49B6FF).withOpacity(0.30 + t * 0.15),
                        Colors.transparent,
                      ]),
                    ),
                    child: Transform.translate(
                      offset: Offset(0, -2 + t * 4),
                      child: DiamondGem(size: 78, colors: _gem, shine: t),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('YOUR BALANCE',
                  style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$balance',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('💎',
                        style: GoogleFonts.poppins(fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                balance > 0
                    ? '≈ $balance message${balance == 1 ? '' : 's'} · 1 diamond each'
                    : 'Top up to chat freely and join Live Dates',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12.5),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----- Perks ----------------------------------------------------------

  Widget _perksRow() {
    final perks = [
      (Icons.chat_bubble_rounded, 'Messaging', 'Chat beyond your free hello'),
      (Icons.videocam_rounded, 'Live Dates', 'Speed & blind-date events'),
      (Icons.visibility_rounded, 'Unveils', 'Reveal your blind dates'),
      (Icons.bolt_rounded, 'Boosts', 'Get seen by more people'),
    ];
    return SizedBox(
      height: 134,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: perks.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (icon, title, sub) = perks[i];
          return Container(
            width: 152,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.darkSurface, const Color(0xFF141416)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppTheme.accentBright, size: 20),
                ),
                const Spacer(),
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(sub,
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 11.5, height: 1.3)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----- Packages -------------------------------------------------------

  /// Lowest price-per-diamond in the catalogue → "BEST VALUE".
  String? _bestValueId(List packages) {
    String? id;
    double best = double.infinity;
    for (final p in packages) {
      final m = p as Map;
      final total = ((m['diamonds'] ?? 0) as num) + ((m['bonus'] ?? 0) as num);
      final price = (m['price'] ?? 0) as num;
      if (total <= 0) continue;
      final ppd = price / total;
      if (ppd < best) {
        best = ppd;
        id = (m['id'] ?? '').toString();
      }
    }
    return id;
  }

  Widget _packageCard(Map pkg, String? bestId) {
    final id = (pkg['id'] ?? '').toString();
    final diamonds = (pkg['diamonds'] ?? 0) as int;
    final price = (pkg['price'] ?? 0).toInt();
    final bonus = (pkg['bonus'] ?? 0) as int;
    final popular = pkg['popular'] == true;
    final isBest = id == bestId;
    final highlight = popular || isBest;
    final total = diamonds + bonus;
    final busy = _busyId == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: busy ? null : () => _showPurchaseSheet(id, diamonds, price, bonus),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [const Color(0xFF20140F), const Color(0xFF141014)]
                  : [AppTheme.darkSurface, const Color(0xFF141416)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlight
                  ? AppTheme.accent.withOpacity(0.55)
                  : Colors.white.withOpacity(0.07),
              width: highlight ? 1.5 : 1,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                        color: AppTheme.accent.withOpacity(0.20),
                        blurRadius: 26,
                        offset: const Offset(0, 10))
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (popular || isBest)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Text(popular ? 'POPULAR' : 'BEST VALUE',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DiamondGem(size: 52, colors: _gem, shine: 0.5),
                    const SizedBox(height: 14),
                    Text('$total',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    Text('diamonds',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 8),
                    if (bonus > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text('+$bonus bonus',
                            style: GoogleFonts.poppins(
                                color: AppTheme.accentBright,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700)),
                      )
                    else
                      Text('₦${(price / max(total, 1)).toStringAsFixed(0)} / 💎',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 10.5)),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: highlight ? AppTheme.accentGradient : null,
                        color: highlight ? null : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: highlight
                            ? null
                            : Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Center(
                        child: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('₦${_money(price)}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustRow() {
    Widget item(IconData i, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text(t,
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 11.5)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item(Icons.lock_rounded, 'Secure'),
        item(Icons.flash_on_rounded, 'Instant'),
        item(Icons.verified_user_rounded, 'Paystack'),
      ],
    );
  }

  Widget _historyButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showTransactions,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white54, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Purchase history',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: GoogleFonts.poppins(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700));

  String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ----- Purchase flow --------------------------------------------------

  void _showPurchaseSheet(String packageId, int diamonds, int price, int bonus) {
    final total = diamonds + bonus;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 22),
            DiamondGem(size: 68, colors: _gem, shine: 0.55),
            const SizedBox(height: 16),
            Text('$total diamonds',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            if (bonus > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Includes $bonus bonus diamonds',
                    style: GoogleFonts.poppins(
                        color: AppTheme.accentBright, fontSize: 13)),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 15)),
                  Text('₦${_money(price)}',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accent.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(ctx);
                      _processPurchase(packageId);
                    },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Pay ₦${_money(price)}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Secured by Paystack · diamonds credited instantly',
                style:
                    GoogleFonts.poppins(color: Colors.white38, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _processPurchase(String packageId) async {
    // Play Store builds must use Google Play Billing for virtual currency.
    if (kUseGooglePlayBilling) {
      _toast('In-app purchases will be available in the Play Store build soon.',
          AppTheme.darkSurface2);
      return;
    }

    final wallet = context.read<WalletProvider>();
    setState(() => _busyId = packageId);
    try {
      final result = await wallet.service.initializePurchase(packageId);
      if (!mounted) return;
      final authorizationUrl = result['authorizationUrl']?.toString();
      final reference = result['reference']?.toString() ?? '';
      if (authorizationUrl == null || reference.isEmpty) {
        throw Exception('Could not start payment');
      }

      // Open the secure in-app checkout, then verify with the backend.
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutPage(
            authorizationUrl: authorizationUrl,
            reference: reference,
          ),
        ),
      );

      if (!mounted) return;
      if (completed == true) {
        await _verifyPayment(reference);
      } else {
        // User backed out — verify quietly in case they actually paid.
        await _verifyPayment(reference, silentPending: true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('PAYMENT_NOT_CONFIGURED')) {
        _toast('Diamond purchases aren\'t enabled yet. Please check back soon.',
            AppTheme.darkSurface2);
      } else {
        _toast('Could not start purchase: ${msg.replaceAll('Exception: ', '')}',
            Colors.red);
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _verifyPayment(String reference,
      {bool silentPending = false}) async {
    final wallet = context.read<WalletProvider>();
    try {
      final result = await wallet.service.verifyPurchase(reference);
      final status = (result['status'] ?? '').toString().toUpperCase();
      final newBalance = (result['balance'] ?? wallet.balance) as int;
      final diamonds = (result['diamonds'] ?? 0) as int;
      wallet.setBalance(newBalance);

      if (!mounted) return;
      if (status == 'COMPLETED' || status == 'SUCCESS' || diamonds > 0) {
        _showSuccess(diamonds, newBalance);
      } else if (!silentPending) {
        _toast('Payment is still processing. Pull to refresh in a moment.',
            AppTheme.darkSurface2);
      }
    } catch (e) {
      if (mounted && !silentPending) {
        _toast(
            'Payment not confirmed yet: ${e.toString().replaceAll('Exception: ', '')}',
            Colors.red);
      }
    }
  }

  void _showSuccess(int diamonds, int balance) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF161B24), Color(0xFF0D0D10)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF49B6FF).withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF49B6FF).withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 16)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiamondGem(size: 88, colors: _gem, shine: 0.6),
              const SizedBox(height: 18),
              Text(diamonds > 0 ? '+$diamonds diamonds' : 'Payment received',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('New balance: $balance 💎',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Awesome',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Transactions ---------------------------------------------------

  void _showTransactions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            Text('Purchase history',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: context.read<WalletProvider>().service.getTransactions(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppTheme.accent));
                  }
                  final txns = snap.data ?? [];
                  if (txns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: Colors.white.withOpacity(0.2), size: 48),
                          const SizedBox(height: 12),
                          Text('No purchases yet',
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: txns.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.white.withOpacity(0.06), height: 22),
                    itemBuilder: (context, i) =>
                        _txnRow(Map<String, dynamic>.from(txns[i])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _txnRow(Map<String, dynamic> t) {
    final diamonds = (t['diamonds'] ?? 0) as int;
    final amount = (t['amount'] ?? t['price'] ?? 0);
    final status = (t['status'] ?? '').toString().toUpperCase();
    final created = t['createdAt']?.toString();
    final ok = status == 'COMPLETED' || status == 'SUCCESS';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (ok ? AppTheme.accent : Colors.white24).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ok ? Icons.diamond : Icons.hourglass_empty_rounded,
              color: ok ? AppTheme.accent : Colors.white54, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('+$diamonds diamonds',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_formatDate(created),
                  style: GoogleFonts.poppins(
                      color: Colors.white38, fontSize: 11.5)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₦${_money((amount as num).toInt())}',
                style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(ok ? 'Completed' : status.isEmpty ? 'Pending' : status.toLowerCase(),
                style: GoogleFonts.poppins(
                    color: ok ? AppTheme.accentBright : Colors.white38,
                    fontSize: 11)),
          ],
        ),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
