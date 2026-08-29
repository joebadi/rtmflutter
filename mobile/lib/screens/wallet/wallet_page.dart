import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/payment_config.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/diamond_gem.dart';
import 'paystack_checkout_page.dart';

/// RTM Reserve — a deliberately quiet, private-banking take on the diamond
/// wallet. Purchase, verification and history behaviour remain server-backed.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF0B090C);
  static const _panel = Color(0xFF151216);
  static const _wine = Color(0xFF5E1424);
  static const _wineBright = Color(0xFF9E2942);
  static const _gold = Color(0xFFE7C98B);
  static const _goldMuted = Color(0xFF9D8154);
  static const _cream = Color(0xFFF5EFE4);
  static const _gem = [Color(0xFFFFF1BF), Color(0xFFE7C98B), Color(0xFF9D6B2D)];

  static const List<Map<String, dynamic>> _fallbackPackages = [
    {
      'id': 'dp_100',
      'diamonds': 100,
      'price': 1500,
      'bonus': 0,
      'popular': false,
    },
    {
      'id': 'dp_500',
      'diamonds': 500,
      'price': 6500,
      'bonus': 50,
      'popular': true,
    },
    {
      'id': 'dp_1000',
      'diamonds': 1000,
      'price': 12000,
      'bonus': 150,
      'popular': false,
    },
    {
      'id': 'dp_2500',
      'diamonds': 2500,
      'price': 28000,
      'bonus': 500,
      'popular': false,
    },
  ];

  late final AnimationController _glow;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
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
    final packages = wallet.packages.isNotEmpty
        ? wallet.packages
        : _fallbackPackages;
    final gatewayName = _activeGatewayName(wallet.paymentGateways);

    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                if (wallet.isLoading)
                  const LinearProgressIndicator(
                    minHeight: 1,
                    color: _gold,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: _wineBright,
                    backgroundColor: _cream,
                    onRefresh: wallet.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 44),
                      children: [
                        _reserveCard(wallet.balance),
                        const SizedBox(height: 18),
                        _utilityStrip(),
                        const SizedBox(height: 30),
                        _sectionHeading(
                          'Add to your reserve',
                          'One-time purchase',
                        ),
                        const SizedBox(height: 14),
                        if (wallet.loadedOnce && !wallet.paymentsEnabled) ...[
                          _paymentsPausedNotice(),
                          const SizedBox(height: 14),
                        ],
                        ...packages.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _packageTile(
                              Map<String, dynamic>.from(item as Map),
                              _bestValueId(packages),
                              wallet.paymentsEnabled,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _securityFooter(gatewayName, wallet.paymentsEnabled),
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

  Widget _background() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.9, -1),
              radius: 1.25,
              colors: [
                _wine.withOpacity(0.22 + (_glow.value * 0.07)),
                _ink.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: _cream),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RTM RESERVE',
                  style: GoogleFonts.poppins(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                Text(
                  'Wallet',
                  style: GoogleFonts.playfairDisplay(
                    color: _cream,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Purchase history',
            onPressed: _showTransactions,
            icon: const Icon(Icons.receipt_long_outlined, color: _cream),
          ),
        ],
      ),
    );
  }

  Widget _reserveCard(int balance) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) => Container(
        height: 226,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A111C), Color(0xFF171115), Color(0xFF0E0C0E)],
            stops: [0, 0.58, 1],
          ),
          border: Border.all(color: _gold.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: _wine.withOpacity(0.22 + _glow.value * 0.1),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -34,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withOpacity(0.08), width: 24),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: GoogleFonts.poppins(
                        color: _cream.withOpacity(0.58),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                    DiamondGem(size: 34, colors: _gem, shine: _glow.value),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(balance),
                      style: GoogleFonts.playfairDisplay(
                        color: _cream,
                        fontSize: 55,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 5),
                      child: Text(
                        'DIAMONDS',
                        style: GoogleFonts.poppins(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: _goldMuted, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        balance > 0
                            ? '$balance meaningful conversation${balance == 1 ? '' : 's'} within reach'
                            : 'Your next meaningful connection starts here',
                        style: GoogleFonts.poppins(
                          color: _cream.withOpacity(0.56),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    Text(
                      'READY TO MARRY',
                      style: GoogleFonts.poppins(
                        color: _cream.withOpacity(0.25),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _utilityStrip() {
    final items = [
      (Icons.forum_outlined, 'Message'),
      (Icons.visibility_outlined, 'Unveil'),
      (Icons.video_camera_front_outlined, 'Live date'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: _panel.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: index == items.length - 1
                    ? null
                    : Border(
                        right: BorderSide(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
              ),
              child: Column(
                children: [
                  Icon(item.$1, color: _gold, size: 21),
                  const SizedBox(height: 7),
                  Text(
                    item.$2,
                    style: GoogleFonts.poppins(
                      color: _cream.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionHeading(String title, String trailing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: _cream,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.poppins(
            color: _cream.withOpacity(0.34),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _paymentsPausedNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, color: _gold, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Top-ups are temporarily unavailable. Your existing balance remains ready to use.',
              style: GoogleFonts.poppins(
                color: _cream.withOpacity(0.7),
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _bestValueId(List<dynamic> packages) {
    String? bestId;
    double bestRate = double.infinity;
    for (final item in packages) {
      final package = item as Map;
      final total =
          (package['diamonds'] as num? ?? 0) + (package['bonus'] as num? ?? 0);
      final price = package['price'] as num? ?? 0;
      if (total <= 0) continue;
      final rate = price / total;
      if (rate < bestRate) {
        bestRate = rate;
        bestId = package['id']?.toString();
      }
    }
    return bestId;
  }

  Widget _packageTile(
    Map<String, dynamic> package,
    String? bestId,
    bool paymentsEnabled,
  ) {
    final id = package['id']?.toString() ?? '';
    final diamonds = (package['diamonds'] as num? ?? 0).toInt();
    final bonus = (package['bonus'] as num? ?? 0).toInt();
    final price = (package['price'] as num? ?? 0).toInt();
    final total = diamonds + bonus;
    final featured = package['popular'] == true;
    final best = id == bestId;
    final busy = _busyId == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: busy
            ? null
            : () {
                if (!paymentsEnabled) {
                  _toast('Top-ups are temporarily unavailable.', _panel);
                  return;
                }
                _showPurchaseSheet(id, diamonds, price, bonus);
              },
        child: AnimatedOpacity(
          opacity: paymentsEnabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
            decoration: BoxDecoration(
              color: featured ? const Color(0xFF211317) : _panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: featured
                    ? _gold.withOpacity(0.42)
                    : Colors.white.withOpacity(0.065),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: featured
                        ? _wine.withOpacity(0.5)
                        : Colors.white.withOpacity(0.035),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Center(
                    child: DiamondGem(size: 31, colors: _gem, shine: 0.55),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$total',
                            style: GoogleFonts.playfairDisplay(
                              color: _cream,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'diamonds',
                            style: GoogleFonts.poppins(
                              color: _cream.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (bonus > 0)
                        Text(
                          '$diamonds + $bonus complimentary',
                          style: GoogleFonts.poppins(
                            color: _gold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          '₦${(price / max(total, 1)).toStringAsFixed(0)} per diamond',
                          style: GoogleFonts.poppins(
                            color: _cream.withOpacity(0.34),
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (featured || best)
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          featured ? 'MOST CHOSEN' : 'BEST VALUE',
                          style: GoogleFonts.poppins(
                            color: _gold,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _gold,
                            ),
                          )
                        : Text(
                            '₦${_money(price)}',
                            style: GoogleFonts.poppins(
                              color: _cream,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ],
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _cream.withOpacity(0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _securityFooter(String gatewayName, bool enabled) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _showTransactions,
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('View purchase history'),
          style: TextButton.styleFrom(
            foregroundColor: _cream.withOpacity(0.58),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              enabled ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
              color: _goldMuted,
              size: 14,
            ),
            const SizedBox(width: 7),
            Text(
              enabled
                  ? 'Secure checkout by $gatewayName'
                  : 'Purchases managed by RTM',
              style: GoogleFonts.poppins(
                color: _cream.withOpacity(0.32),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _activeGatewayName(List<dynamic> gateways) {
    for (final item in gateways) {
      final gateway = item as Map;
      if (gateway['isAvailable'] == true) {
        return gateway['name']?.toString() ?? 'our payment partner';
      }
    }
    return 'our payment partner';
  }

  void _showPurchaseSheet(
    String packageId,
    int diamonds,
    int price,
    int bonus,
  ) {
    final total = diamonds + bonus;
    final gatewayName = _activeGatewayName(
      context.read<WalletProvider>().paymentGateways,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 13, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'CONFIRM TOP-UP',
                style: GoogleFonts.poppins(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$total diamonds',
                style: GoogleFonts.playfairDisplay(
                  color: _cream,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (bonus > 0)
                Text(
                  'Includes $bonus complimentary diamonds',
                  style: GoogleFonts.poppins(
                    color: _cream.withOpacity(0.48),
                    fontSize: 11.5,
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: _ink.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total due',
                      style: GoogleFonts.poppins(
                        color: _cream.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₦${_money(price)}',
                      style: GoogleFonts.poppins(
                        color: _cream,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wineBright,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _processPurchase(packageId);
                  },
                  child: Text(
                    'Continue securely',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                '$gatewayName encrypted checkout · instant credit',
                style: GoogleFonts.poppins(
                  color: _cream.withOpacity(0.3),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPurchase(String packageId) async {
    if (kUseGooglePlayBilling) {
      _toast(
        'In-app purchases will be available in the Play Store build soon.',
        _panel,
      );
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

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutPage(
            authorizationUrl: authorizationUrl,
            reference: reference,
          ),
        ),
      );
      if (!mounted) return;
      await _verifyPayment(reference, silentPending: completed != true);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      if (message.contains('PAYMENT_NOT_CONFIGURED')) {
        await wallet.refresh();
        _toast(
          'Top-ups are temporarily unavailable. Please check back soon.',
          _panel,
        );
      } else {
        _toast(
          'Could not start purchase: ${message.replaceAll('Exception: ', '')}',
          Colors.red.shade800,
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _verifyPayment(
    String reference, {
    bool silentPending = false,
  }) async {
    final wallet = context.read<WalletProvider>();
    try {
      final result = await wallet.service.verifyPurchase(reference);
      final status = (result['status'] ?? '').toString().toUpperCase();
      final newBalance = (result['balance'] as num? ?? wallet.balance).toInt();
      final diamonds = (result['diamonds'] as num? ?? 0).toInt();
      wallet.setBalance(newBalance);

      if (!mounted) return;
      if (status == 'COMPLETED' || status == 'SUCCESS' || diamonds > 0) {
        _showSuccess(diamonds, newBalance);
      } else if (!silentPending) {
        _toast('Payment is still processing. Pull to refresh shortly.', _panel);
      }
    } catch (error) {
      if (mounted && !silentPending) {
        _toast(
          'Payment not confirmed yet: ${error.toString().replaceAll('Exception: ', '')}',
          Colors.red.shade800,
        );
      }
    }
  }

  void _showSuccess(int diamonds, int balance) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.76),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(27, 31, 27, 23),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: _gold.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiamondGem(size: 72, colors: _gem, shine: 0.72),
              const SizedBox(height: 17),
              Text(
                diamonds > 0 ? '+$diamonds diamonds' : 'Payment received',
                style: GoogleFonts.playfairDisplay(
                  color: _cream,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reserve balance · ${_money(balance)}',
                style: GoogleFonts.poppins(
                  color: _cream.withOpacity(0.48),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 23),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wineBright,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 13),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Purchase history',
              style: GoogleFonts.playfairDisplay(
                color: _cream,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: context
                    .read<WalletProvider>()
                    .service
                    .getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold),
                    );
                  }
                  final transactions = snapshot.data ?? [];
                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: _cream.withOpacity(0.17),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No purchases yet',
                            style: GoogleFonts.poppins(
                              color: _cream.withOpacity(0.42),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.06),
                      height: 22,
                    ),
                    itemBuilder: (_, index) => _transactionRow(
                      Map<String, dynamic>.from(transactions[index] as Map),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionRow(Map<String, dynamic> transaction) {
    final metadata = transaction['metadata'] is Map
        ? transaction['metadata'] as Map
        : const {};
    final diamonds =
        (transaction['diamonds'] as num? ?? metadata['diamonds'] as num? ?? 0)
            .toInt();
    final amount =
        (transaction['amount'] as num? ?? transaction['price'] as num? ?? 0)
            .toInt();
    final status = (transaction['status'] ?? '').toString().toUpperCase();
    final complete = status == 'COMPLETED' || status == 'SUCCESS';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (complete ? _gold : Colors.white).withOpacity(0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            complete ? Icons.diamond_outlined : Icons.schedule_rounded,
            color: complete ? _gold : Colors.white38,
            size: 20,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+$diamonds diamonds',
                style: GoogleFonts.poppins(
                  color: _cream,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(transaction['createdAt']?.toString()),
                style: GoogleFonts.poppins(
                  color: _cream.withOpacity(0.32),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₦${_money(amount)}',
              style: GoogleFonts.poppins(
                color: _cream,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              complete ? 'Completed' : status.toLowerCase(),
              style: GoogleFonts.poppins(
                color: complete ? _gold : Colors.white38,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _money(int value) {
    final raw = value.toString();
    final output = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      if (index > 0 && (raw.length - index) % 3 == 0) output.write(',');
      output.write(raw[index]);
    }
    return output.toString();
  }

  String _formatDate(String? iso) {
    final date = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
