import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/live_service.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/premium_loader.dart';

/// Post-event results: a celebratory matches header, then everyone you met —
/// with your private rating/interest and, for blind dates, the option to
/// unveil partners you didn't match with (free quota, then diamonds).
class LiveEventResultsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const LiveEventResultsScreen({
    super.key,
    required this.eventId,
    this.eventTitle = 'Live Date',
  });

  @override
  State<LiveEventResultsScreen> createState() => _LiveEventResultsScreenState();
}

class _LiveEventResultsScreenState extends State<LiveEventResultsScreen> {
  final LiveService _live = LiveService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  final Set<String> _unveiling = {}; // pairingIds with an in-flight unveil

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _live.getEventResults(widget.eventId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  List<Map<String, dynamic>> get _pairings =>
      ((_data?['pairings'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<Map<String, dynamic>> get _matches =>
      _pairings.where((p) => p['isMatch'] == true).toList();

  // ----- Unveil -----------------------------------------------------------

  Future<void> _unveil(Map<String, dynamic> pairing) async {
    final pairingId = pairing['pairingId'].toString();
    if (_unveiling.contains(pairingId)) return;

    final unveils = (_data?['unveils'] as Map?) ?? {};
    final remaining = (unveils['remaining'] ?? 0) as int;
    final cost = (unveils['cost'] ?? 0) as int;
    final isFree = remaining > 0 || cost <= 0;

    if (!isFree) {
      final ok = await _confirmPaidUnveil(cost);
      if (ok != true) return;
    }

    setState(() => _unveiling.add(pairingId));
    try {
      final result = await _live.unveilPartner(pairingId);
      if (!mounted) return;
      // Update wallet + this row + remaining-unveils counter in place.
      if (result['diamondBalance'] != null) {
        context.read<WalletProvider>().setBalance(result['diamondBalance'] as int);
      }
      setState(() {
        pairing['partner'] = Map<String, dynamic>.from(result['partner']);
        pairing['revealed'] = true;
        pairing['unveiled'] = true;
        pairing['canUnveil'] = false;
        if (_data != null) {
          _data!['unveils'] = {
            ...unveils,
            'used': result['unveilsUsed'] ?? unveils['used'],
            'remaining': result['unveilsRemaining'] ?? unveils['remaining'],
          };
        }
      });
      final name = (result['partner']?['firstName'] ?? 'your date').toString();
      _toast(
        (result['free'] == true)
            ? 'Revealed $name'
            : 'Revealed $name · $cost 💎 spent',
        AppTheme.accent,
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('INSUFFICIENT_DIAMONDS')) {
        context.read<WalletProvider>().refresh();
        _showTopUp();
      } else {
        _toast(e.toString().replaceAll('Exception: ', ''), Colors.red);
      }
    } finally {
      if (mounted) setState(() => _unveiling.remove(pairingId));
    }
  }

  Future<bool?> _confirmPaidUnveil(int cost) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unveil this date?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'You\'ve used your free reveals. Spend $cost diamonds to see who this was?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not now', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Unveil · $cost 💎',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showTopUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Not enough diamonds',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Top up to unveil more of your dates.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Maybe later', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet');
            },
            child: Text('Get Diamonds',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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

  // ----- Build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _loading
                  ? const Center(child: PremiumLoader())
                  : _error != null
                      ? _buildError()
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/live-dates'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text('Your results',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          Consumer<WalletProvider>(
            builder: (context, wallet, _) => GestureDetector(
              onTap: () => context.push('/wallet'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond, color: AppTheme.accent, size: 16),
                    const SizedBox(width: 5),
                    Text('${wallet.balance}',
                        style: GoogleFonts.poppins(
                            color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final matches = _matches;
    final everyone = _pairings;
    final blind = _data?['blind'] == true;
    final unveils = (_data?['unveils'] as Map?) ?? {};
    final remaining = (unveils['remaining'] ?? 0) as int;

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.darkSurface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _hero(matches.length),
          const SizedBox(height: 24),

          if (matches.isNotEmpty) ...[
            _sectionTitle('Your matches', '${matches.length}'),
            const SizedBox(height: 12),
            ...matches.map(_matchCard),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Expanded(child: _sectionTitle('Everyone you met', '${everyone.length}')),
              if (blind && remaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$remaining free reveal${remaining == 1 ? '' : 's'} left',
                      style: GoogleFonts.poppins(
                          color: AppTheme.accentBright, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (everyone.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('You didn\'t get paired this event.',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
              ),
            )
          else
            ...everyone.map((p) => _metRow(p, blind)),
        ],
      ),
    );
  }

  Widget _hero(int matchCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent.withOpacity(0.25), AppTheme.heart.withOpacity(0.18)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(gradient: AppTheme.accentGradient, shape: BoxShape.circle),
            child: Icon(matchCount > 0 ? Icons.favorite_rounded : Icons.celebration_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            matchCount > 0
                ? '$matchCount match${matchCount == 1 ? '' : 'es'}!'
                : 'Thanks for joining!',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              matchCount > 0
                  ? 'You both said yes — your chats are unlocked and free.'
                  : 'No mutual matches this time, but your next date could be the one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String count) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(count,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _matchCard(Map<String, dynamic> p) {
    final partner = (p['partner'] as Map?) ?? {};
    final name = (partner['firstName'] ?? 'Your match').toString();
    final age = partner['age'];
    final photo = _fullUrl(partner['photoUrl']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent.withOpacity(0.18), AppTheme.darkSurface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          _avatar(photo, 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(age != null ? '$name, $age' : name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.favorite_rounded, color: AppTheme.heart, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text('It\'s a match · chat unlocked',
                    style: GoogleFonts.poppins(color: AppTheme.accentBright, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.go('/messages'),
            child: Text('Message',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _metRow(Map<String, dynamic> p, bool blind) {
    final partner = (p['partner'] as Map?) ?? {};
    final revealed = p['revealed'] == true;
    final isMatch = p['isMatch'] == true;
    final canUnveil = p['canUnveil'] == true;
    final round = p['roundNumber'];
    final rating = (p['myRating'] as int?) ?? 0;
    final interest = p['myInterest']; // true / false / null
    final name = revealed ? (partner['firstName'] ?? 'Your date').toString() : 'Hidden date';
    final age = partner['age'];
    final photo = _fullUrl(partner['photoUrl']?.toString());
    final pairingId = p['pairingId'].toString();
    final busy = _unveiling.contains(pairingId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _avatar(photo, 48, obscured: !revealed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(revealed && age != null ? '$name, $age' : name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    if (isMatch) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.favorite_rounded, color: AppTheme.heart, size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Round $round',
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                    if (rating > 0) ...[
                      const SizedBox(width: 8),
                      ...List.generate(
                        rating,
                        (_) => const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 13),
                      ),
                    ],
                    if (interest == true && !isMatch) ...[
                      const SizedBox(width: 8),
                      _tag('You liked', AppTheme.accent),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (canUnveil)
            _unveilButton(p, busy)
          else if (isMatch)
            TextButton(
              onPressed: () => context.go('/messages'),
              child: Text('Chat',
                  style: GoogleFonts.poppins(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _unveilButton(Map<String, dynamic> p, bool busy) {
    final unveils = (_data?['unveils'] as Map?) ?? {};
    final remaining = (unveils['remaining'] ?? 0) as int;
    final cost = (unveils['cost'] ?? 0) as int;
    final isFree = remaining > 0 || cost <= 0;

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent.withOpacity(0.16),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: busy ? null : () => _unveil(p),
        child: busy
            ? const SizedBox(
                width: 16, height: 16,
                child: PremiumLoader(strokeWidth: 2, color: AppTheme.accent),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_rounded, color: AppTheme.accent, size: 15),
                  const SizedBox(width: 5),
                  Text(isFree ? 'Reveal' : '$cost 💎',
                      style: GoogleFonts.poppins(
                          color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _avatar(String url, double size, {bool obscured = false}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.darkSurface2,
        border: Border.all(color: Colors.white12, width: 1.5),
      ),
      child: obscured || url.isEmpty
          ? Icon(obscured ? Icons.visibility_off_rounded : Icons.person,
              color: Colors.white30, size: size * 0.45)
          : Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.person, color: Colors.white30, size: size * 0.45)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.white38),
          const SizedBox(height: 14),
          Text(_error ?? 'Couldn\'t load results',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _load,
            child: Text('Retry',
                style: GoogleFonts.poppins(color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
