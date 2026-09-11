import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/payment_config.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/diamond_gem.dart';
import 'paystack_checkout_page.dart';

/// Premium diamond wallet inspired by the app's splash palette. Purchase,
/// verification and history behaviour remain server-backed.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  static const _wineBright = Color(0xFFF45B45);
  static const _orange = Color(0xFFFF5722);
  static const _orangeLight = Color(0xFFFF7043);
  static const _gold = Color(0xFFF4B860);
  static const _goldMuted = Color(0xFFF08A7C);
  static const _gem = [Color(0xFFE8FCFF), Color(0xFF70DFF4), Color(0xFF8978F7)];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => _isDark ? const Color(0xFF180B14) : const Color(0xFFFFF7FA);
  Color get _panel => _isDark ? const Color(0xFF281520) : Colors.white;
  Color get _wine =>
      _isDark ? const Color(0xFF3A1128) : const Color(0xFFFFE5ED);
  Color get _cream => _isDark ? Colors.white : const Color(0xFF21141C);
  Color get _muted =>
      _isDark ? Colors.white.withValues(alpha: 0.62) : const Color(0xFF715E69);
  Color get _stroke => _isDark
      ? Colors.white.withValues(alpha: 0.09)
      : const Color(0xFF3A1128).withValues(alpha: 0.09);

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
  String? _selectedPackageId;

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
    final normalizedPackages = packages
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final bestValueId = _bestValueId(packages);
    final packageIds = normalizedPackages
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final selectedId = packageIds.contains(_selectedPackageId)
        ? _selectedPackageId
        : (bestValueId ?? (packageIds.isEmpty ? null : packageIds.first));
    final selectedPackage = selectedId == null
        ? null
        : normalizedPackages.firstWhere(
            (item) => item['id']?.toString() == selectedId,
          );
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
                    color: _wineBright,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: _wineBright,
                    backgroundColor: _cream,
                    onRefresh: wallet.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                      children: [
                        _balanceCard(wallet.balance),
                        const SizedBox(height: 20),
                        _sectionHeading(
                          'Choose your diamonds',
                          'One-time top-up',
                        ),
                        const SizedBox(height: 10),
                        if (wallet.loadedOnce && !wallet.paymentsEnabled) ...[
                          _paymentsPausedNotice(),
                          const SizedBox(height: 10),
                        ],
                        ...normalizedPackages.map(
                          (package) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _packageTile(
                              package,
                              bestValueId,
                              selectedId,
                              wallet.paymentsEnabled,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _benefitsCard(),
                        const SizedBox(height: 16),
                        if (selectedPackage != null)
                          _purchaseButton(
                            selectedPackage,
                            wallet.paymentsEnabled,
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
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDark
                  ? const [
                      Color(0xFF180B14),
                      Color(0xFF3A1128),
                      Color(0xFF210E18),
                    ]
                  : const [
                      Color(0xFFFFFBF9),
                      Color(0xFFFFEEE9),
                      Color(0xFFFFF8F5),
                    ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -90,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _wineBright.withValues(
                          alpha: (_isDark ? 0.14 : 0.10) + _glow.value * 0.04,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -160,
                left: -120,
                child: Container(
                  width: 330,
                  height: 330,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFFE91E63,
                        ).withValues(alpha: _isDark ? 0.12 : 0.07),
                        Colors.transparent,
                      ],
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 8, 2),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_rounded, color: _cream),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet',
                  style: GoogleFonts.poppins(
                    color: _cream,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Diamonds for deeper connections',
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Purchase history',
            onPressed: _showTransactions,
            icon: Icon(Icons.receipt_long_outlined, color: _cream),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(int balance) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) => Container(
        height: 178,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A1128), _orange, _orangeLight],
            stops: [0, 0.54, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(
                alpha: (_isDark ? 0.22 : 0.16) + _glow.value * 0.04,
              ),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -48,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 20,
                  ),
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
                      'YOUR DIAMOND BALANCE',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: DiamondGem(
                        size: 28,
                        colors: _gem,
                        shine: _glow.value,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(balance),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 3),
                      child: Text(
                        'DIAMONDS',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        balance > 0
                            ? 'Ready for messages, unveils and live dates'
                            : 'Your next meaningful connection starts here',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 10,
                        ),
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

  Widget _benefitsCard() {
    final items = [
      (Icons.forum_rounded, 'Keep meaningful conversations going'),
      (Icons.visibility_rounded, 'Unveil your Live Date connections'),
      (Icons.video_camera_front_rounded, 'Join more face-to-face Live Dates'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: _isDark ? 0.86 : 0.94),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What your diamonds unlock',
            style: GoogleFonts.poppins(
              color: _cream,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A1128), _orange],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$1, color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.poppins(
                        color: _muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            style: GoogleFonts.poppins(
              color: _cream,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.poppins(color: _muted, fontSize: 9.5),
        ),
      ],
    );
  }

  Widget _paymentsPausedNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, color: _gold, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Top-ups are temporarily unavailable. Your existing balance remains ready to use.',
              style: GoogleFonts.poppins(
                color: _muted,
                fontSize: 10.5,
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
    String? selectedId,
    bool paymentsEnabled,
  ) {
    final id = package['id']?.toString() ?? '';
    final diamonds = (package['diamonds'] as num? ?? 0).toInt();
    final bonus = (package['bonus'] as num? ?? 0).toInt();
    final price = (package['price'] as num? ?? 0).toInt();
    final total = diamonds + bonus;
    final featured = package['popular'] == true;
    final best = id == bestId;
    final selected = id == selectedId;
    final busy = _busyId == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: busy ? null : () => setState(() => _selectedPackageId = id),
        child: AnimatedOpacity(
          opacity: paymentsEnabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 11, 10),
            decoration: BoxDecoration(
              color: _panel.withValues(alpha: _isDark ? 0.90 : 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _orange : _stroke,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _orange.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF3A1128), _orange],
                          )
                        : null,
                    color: selected ? null : _wine,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: DiamondGem(size: 25, colors: _gem, shine: 0.55),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$total',
                            style: GoogleFonts.poppins(
                              color: _cream,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'diamonds',
                            style: GoogleFonts.poppins(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      if (bonus > 0)
                        Text(
                          '$diamonds + $bonus complimentary',
                          style: GoogleFonts.poppins(
                            color: _isDark ? _gold : const Color(0xFF9A5C10),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          '₦${(price / max(total, 1)).toStringAsFixed(0)} per diamond',
                          style: GoogleFonts.poppins(
                            color: _muted,
                            fontSize: 9.5,
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
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (selected ? _orange : _gold).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          featured ? 'MOST CHOSEN' : 'BEST VALUE',
                          style: GoogleFonts.poppins(
                            color: selected
                                ? _orange
                                : (_isDark ? _gold : const Color(0xFF9A5C10)),
                            fontSize: 6.8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    busy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _wineBright,
                            ),
                          )
                        : Text(
                            '₦${_money(price)}',
                            style: GoogleFonts.poppins(
                              color: _cream,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ],
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _muted.withValues(alpha: 0.62),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _purchaseButton(Map<String, dynamic> package, bool paymentsEnabled) {
    final id = package['id']?.toString() ?? '';
    final diamonds = (package['diamonds'] as num? ?? 0).toInt();
    final bonus = (package['bonus'] as num? ?? 0).toInt();
    final price = (package['price'] as num? ?? 0).toInt();
    final total = diamonds + bonus;
    final busy = _busyId == id;

    return AnimatedOpacity(
      opacity: paymentsEnabled ? 1 : 0.55,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3A1128), _orange, _orangeLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _orange.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: !paymentsEnabled || busy
                ? null
                : () => _showPurchaseSheet(id, diamonds, price, bonus),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      paymentsEnabled
                          ? 'Continue with $total diamonds'
                          : 'Top-ups temporarily unavailable',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
          style: TextButton.styleFrom(foregroundColor: _muted),
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
              style: GoogleFonts.poppins(color: _muted, fontSize: 10.5),
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
                  color: _muted.withValues(alpha: 0.28),
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
                style: GoogleFonts.poppins(
                  color: _cream,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (bonus > 0)
                Text(
                  'Includes $bonus complimentary diamonds',
                  style: GoogleFonts.poppins(color: _muted, fontSize: 11.5),
                ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: _isDark
                      ? _ink.withValues(alpha: 0.62)
                      : const Color(0xFFFFF3F6),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _stroke),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total due',
                      style: GoogleFonts.poppins(color: _muted, fontSize: 13),
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
                style: GoogleFonts.poppins(color: _muted, fontSize: 10.5),
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
      barrierColor: Colors.black.withValues(alpha: 0.76),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(27, 31, 27, 23),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: _stroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiamondGem(size: 72, colors: _gem, shine: 0.72),
              const SizedBox(height: 17),
              Text(
                diamonds > 0 ? '+$diamonds diamonds' : 'Payment received',
                style: GoogleFonts.poppins(
                  color: _cream,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Wallet balance · ${_money(balance)} diamonds',
                style: GoogleFonts.poppins(color: _muted, fontSize: 12),
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
                color: _muted.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Purchase history',
              style: GoogleFonts.poppins(
                color: _cream,
                fontSize: 22,
                fontWeight: FontWeight.w800,
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
                            color: _muted.withValues(alpha: 0.35),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No purchases yet',
                            style: GoogleFonts.poppins(
                              color: _muted,
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
                    separatorBuilder: (_, __) =>
                        Divider(color: _stroke, height: 22),
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
            color: (complete ? _gold : _muted).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            complete ? Icons.diamond_outlined : Icons.schedule_rounded,
            color: complete ? _gold : _muted,
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
                style: GoogleFonts.poppins(color: _muted, fontSize: 10.5),
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
                color: complete ? _gold : _muted,
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
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF21141C);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: textColor)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
