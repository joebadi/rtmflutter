import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/wallet_provider.dart';

/// The diamonds wallet — balance hero, what diamonds unlock, top-up packages,
/// and purchase history. Dark, premium look matching the Live Dates aesthetic.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with TickerProviderStateMixin {
  late final AnimationController _glow;
  String? _selectedId; // package currently being purchased (for tap feedback)

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
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final balance = wallet.balance;
    final packages = wallet.packages.isNotEmpty ? wallet.packages : _fallbackPackages;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accent,
                backgroundColor: AppTheme.darkSurface,
                onRefresh: () => context.read<WalletProvider>().refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                  children: [
                    _balanceHero(balance),
                    const SizedBox(height: 28),
                    _sectionTitle('Spend diamonds on'),
                    const SizedBox(height: 14),
                    _perksRow(),
                    const SizedBox(height: 28),
                    _sectionTitle('Top up'),
                    const SizedBox(height: 4),
                    Text('Pay once. No subscription.',
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
                    const SizedBox(height: 16),
                    ...List.generate(packages.length, (i) => _packageCard(packages[i] as Map)),
                    const SizedBox(height: 16),
                    _historyButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Header ----------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            child: Text('Wallet',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white70),
            onPressed: _showTransactions,
          ),
        ],
      ),
    );
  }

  // ----- Balance hero ----------------------------------------------------

  Widget _balanceHero(int balance) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final g = 0.25 + _glow.value * 0.25;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF241310), Color(0xFF1A1A1A)],
            ),
            border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(g), blurRadius: 34, offset: const Offset(0, 12)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // faint oversized diamond watermark
              Positioned(
                right: -14,
                top: -10,
                child: Icon(Icons.diamond, size: 120, color: AppTheme.accent.withOpacity(0.06)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 18),
                          ],
                        ),
                        child: const Icon(Icons.diamond, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Text('YOUR BALANCE',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$balance',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1)),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('diamonds',
                            style: GoogleFonts.poppins(
                                color: AppTheme.accentBright, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    balance > 0
                        ? '≈ $balance message${balance == 1 ? '' : 's'} · 1 diamond per message'
                        : 'Top up to start chatting and join Live Dates',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12.5),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ----- Perks -----------------------------------------------------------

  Widget _perksRow() {
    final perks = [
      (Icons.chat_bubble_rounded, 'Messaging', 'Chat beyond your free icebreaker'),
      (Icons.videocam_rounded, 'Live Dates', 'Book speed & blind-date events'),
      (Icons.visibility_rounded, 'Unveils', 'Reveal your blind dates'),
      (Icons.bolt_rounded, 'Boosts', 'Get seen by more people'),
    ];
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: perks.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (icon, title, sub) = perks[i];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.accent, size: 20),
                ),
                const Spacer(),
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(sub,
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.5, height: 1.3)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----- Packages --------------------------------------------------------

  Widget _packageCard(Map pkg) {
    final id = (pkg['id'] ?? '').toString();
    final diamonds = (pkg['diamonds'] ?? 0) as int;
    final price = (pkg['price'] ?? 0).toInt();
    final bonus = (pkg['bonus'] ?? 0) as int;
    final popular = pkg['popular'] == true;
    final total = diamonds + bonus;
    final busy = _selectedId == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: busy ? null : () => _showPurchaseSheet(id, diamonds, price, bonus),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: popular
                    ? [AppTheme.accent.withOpacity(0.18), AppTheme.darkSurface]
                    : [AppTheme.darkSurface, AppTheme.darkSurface2],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: popular ? AppTheme.accent.withOpacity(0.55) : Colors.white.withOpacity(0.06),
                width: popular ? 1.6 : 1,
              ),
              boxShadow: popular
                  ? [BoxShadow(color: AppTheme.accent.withOpacity(0.2), blurRadius: 22, offset: const Offset(0, 8))]
                  : null,
            ),
            child: Row(
              children: [
                _diamondStack(popular),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$total',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Text('diamonds',
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                          if (popular) ...[
                            const SizedBox(width: 8),
                            _ribbon('POPULAR'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bonus > 0
                            ? '$diamonds + $bonus bonus'
                            : '₦${(price / max(diamonds, 1)).toStringAsFixed(0)} per diamond',
                        style: GoogleFonts.poppins(
                            color: bonus > 0 ? AppTheme.accentBright : Colors.white38, fontSize: 12.5,
                            fontWeight: bonus > 0 ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                _priceTag(price, popular, busy),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _diamondStack(bool popular) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent.withOpacity(0.3), AppTheme.accentLight.withOpacity(0.12)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
      ),
      child: const Icon(Icons.diamond, color: AppTheme.accent, size: 28),
    );
  }

  Widget _ribbon(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(7)),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _priceTag(int price, bool popular, bool busy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        gradient: popular ? AppTheme.accentGradient : null,
        color: popular ? null : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: popular ? null : Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: busy
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text('₦${_money(price)}',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
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
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700));

  String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ----- Purchase flow ---------------------------------------------------

  void _showPurchaseSheet(String packageId, int diamonds, int price, int bonus) {
    final total = diamonds + bonus;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.accentGradient,
                boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 24)],
              ),
              child: const Icon(Icons.diamond, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            Text('$total diamonds',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            if (bonus > 0)
              Text('Includes $bonus bonus diamonds',
                  style: GoogleFonts.poppins(color: AppTheme.accentBright, fontSize: 13)),
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
                  Text('Total', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
                  Text('₦${_money(price)}',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
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
                  boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
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
                      child: Text('Pay with Paystack',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Secure checkout · diamonds credited instantly',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _processPurchase(String packageId) async {
    final wallet = context.read<WalletProvider>();
    setState(() => _selectedId = packageId);
    try {
      final result = await wallet.service.initializePurchase(packageId);
      if (!mounted) return;
      final authorizationUrl = result['authorizationUrl']?.toString();
      final reference = result['reference']?.toString() ?? '';
      if (authorizationUrl == null || reference.isEmpty) {
        throw Exception('Could not start payment');
      }
      _showVerifyDialog(reference, authorizationUrl);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('PAYMENT_NOT_CONFIGURED')) {
        _toast('Diamond purchases aren\'t enabled yet. Please check back soon.', AppTheme.darkSurface2);
      } else {
        _toast('Could not start purchase: ${msg.replaceAll('Exception: ', '')}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _selectedId = null);
    }
  }

  void _showVerifyDialog(String reference, String authorizationUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Complete payment',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Open the secure checkout to pay, then tap "I\'ve Paid" to credit your diamonds.\n\nCheckout link:\n$authorizationUrl',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _verifyPayment(reference);
            },
            child: Text("I've Paid", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(String reference) async {
    final wallet = context.read<WalletProvider>();
    try {
      final result = await wallet.service.verifyPurchase(reference);
      final newBalance = (result['balance'] ?? wallet.balance) as int;
      wallet.setBalance(newBalance);
      final diamonds = result['diamonds'] ?? 0;
      if (mounted) _toast('$diamonds diamonds added to your wallet!', AppTheme.accent);
    } catch (e) {
      if (mounted) {
        _toast('Payment not confirmed yet: ${e.toString().replaceAll('Exception: ', '')}', Colors.red);
      }
    }
  }

  // ----- Transactions ----------------------------------------------------

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
              width: 44, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            Text('Purchase history',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: context.read<WalletProvider>().service.getTransactions(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                  }
                  final txns = snap.data ?? [];
                  if (txns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: Colors.white.withOpacity(0.2), size: 48),
                          const SizedBox(height: 12),
                          Text('No purchases yet',
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: txns.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), height: 22),
                    itemBuilder: (context, i) => _txnRow(Map<String, dynamic>.from(txns[i])),
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
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_formatDate(created),
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.5)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₦${_money((amount as num).toInt())}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(ok ? 'Completed' : status.isEmpty ? 'Pending' : status.toLowerCase(),
                style: GoogleFonts.poppins(
                    color: ok ? AppTheme.accentBright : Colors.white38, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
