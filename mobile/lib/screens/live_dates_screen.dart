import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/live_service.dart';
import '../providers/wallet_provider.dart';
import '../widgets/notification_icon.dart';
import '../widgets/app_logo.dart';
import '../widgets/premium_loader.dart';
import '../widgets/live_dates_collage.dart';

/// The Live Dates lobby — a dating-event hub where users discover and book
/// admin-scheduled speed-dating / blind-date events.
class LiveDatesScreen extends StatefulWidget {
  const LiveDatesScreen({super.key});

  @override
  State<LiveDatesScreen> createState() => _LiveDatesScreenState();
}

class _LiveDatesScreenState extends State<LiveDatesScreen> {
  final LiveService _liveService = LiveService();

  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _error;
  Timer? _ticker;
  final Set<String> _busy = {}; // event ids with an in-flight book/cancel

  @override
  void initState() {
    super.initState();
    _load();
    // Tick every second to keep the countdowns live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await _liveService.getEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _fullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  // ----- Booking actions -------------------------------------------------

  Future<void> _book(Map event) async {
    final id = event['id'].toString();
    setState(() => _busy.add(id));
    try {
      await _liveService.bookEvent(id);
      if (!mounted) return;
      context.read<WalletProvider>().refresh();
      _toast('You\'re in! See you at "${event['title']}".', AppTheme.accent);
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('INSUFFICIENT_DIAMONDS')) {
        context.read<WalletProvider>().refresh();
        _showTopUpDialog(event);
      } else {
        _toast(e.toString().replaceAll('Exception: ', ''), Colors.red);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _cancel(Map event) async {
    final id = event['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel booking?',
            style: GoogleFonts.poppins(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: Text(
          'Your diamonds will be refunded if the event hasn\'t started.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary(context), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it', style: GoogleFonts.poppins(color: AppTheme.textSecondary(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel booking', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy.add(id));
    try {
      await _liveService.cancelBooking(id);
      if (!mounted) return;
      context.read<WalletProvider>().refresh();
      _toast('Booking cancelled.', AppTheme.surface2(context));
      await _load();
    } catch (e) {
      if (mounted) _toast(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
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

  void _showTopUpDialog(Map event) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: AppTheme.accent, size: 48),
              const SizedBox(height: 16),
              Text('Not enough diamonds',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary(context), fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '"${event['title']}" costs ${event['diamondCost']} diamonds to join. Top up to book your spot.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary(context), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/wallet');
                  },
                  child: Text('Get Diamonds',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Maybe later', style: GoogleFonts.poppins(color: AppTheme.textFaint(context))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final liveCount = _events.where((e) => e['status'] == 'LIVE').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLogo(height: 20, color: AppTheme.textPrimary(context)),
                const SizedBox(height: 8),
                Text('Live Dates',
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 2),
                Text(
                  liveCount > 0
                      ? '$liveCount event${liveCount > 1 ? 's' : ''} live right now'
                      : 'Meet someone face-to-face',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: liveCount > 0 ? AppTheme.accentBright : AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          // Trailing actions — diamond balance chip + notification bell, kept on
          // one baseline and aligned with each other.
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Consumer<WalletProvider>(
                builder: (context, wallet, _) => GestureDetector(
                  onTap: () => context.push('/wallet'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond,
                            color: AppTheme.accent, size: 16),
                        const SizedBox(width: 5),
                        Text('${wallet.balance}',
                            style: GoogleFonts.poppins(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NotificationIcon(isDark: !AppTheme.isLight(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final live = _events.where((e) => e['status'] == 'LIVE').toList();
    final upcoming = _events.where((e) => e['status'] != 'LIVE').toList();

    final children = <Widget>[];
    var idx = 0;
    if (live.isNotEmpty) {
      children.add(_sectionHeader('Happening now', AppTheme.accentBright, live: true));
      for (final e in live) {
        children.add(_buildEventCard(e as Map, index: idx++));
      }
    }
    if (upcoming.isNotEmpty) {
      children.add(_sectionHeader(
          live.isEmpty ? 'Upcoming events' : 'Coming up', AppTheme.textSecondary(context)));
      for (final e in upcoming) {
        children.add(_buildEventCard(e as Map, index: idx++));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _sectionHeader(String label, Color color, {bool live = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
      child: Row(
        children: [
          if (live)
            const _PulsingDot(color: AppTheme.accentBright, size: 9)
          else
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
          const SizedBox(width: 9),
          Text(
            label,
            style: GoogleFonts.poppins(
                color: color, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map event, {int index = 0}) {
    final type = event['type']?.toString() ?? 'SPEED_DATING';
    final isBlind = type == 'BLIND_DATE';
    final status = event['status']?.toString() ?? 'SCHEDULED';
    final isLive = status == 'LIVE';
    final cost = (event['diamondCost'] ?? 0) as int;
    final capacity = (event['capacity'] ?? 0) as int;
    final booked = (event['bookedCount'] ?? 0) as int;
    final spotsLeft = (event['spotsLeft'] ?? 0) as int;
    final isFull = event['isFull'] == true;
    final myStatus = event['myBookingStatus']?.toString();
    final iAmBooked = myStatus == 'BOOKED' || myStatus == 'ATTENDED';
    final attendees = (event['attendeePreview'] as List?) ?? [];
    final coverUrl = _fullUrl(event['coverImageUrl']?.toString());

    final accent = isBlind ? const Color(0xFF8E5BD8) : AppTheme.accent;
    final accentLight = isBlind ? const Color(0xFFB388E0) : AppTheme.accentLight;

    // Whole-card tap is a fast path to "Join Room" while an event is live and
    // you're booked; otherwise it's a no-op (the explicit CTA handles booking).
    final VoidCallback? cardTap = (isLive && iAmBooked)
        ? () => context.push('/live-room', extra: {
              'eventId': event['id'].toString(),
              'eventTitle': event['title']?.toString() ?? 'Live Date',
              'audioOnly': isBlind,
            })
        : null;

    return _EntranceFade(
      delayMs: 70 * index,
      child: _PressableScale(
        onTap: cardTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 384,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isLive ? accent : Colors.black).withOpacity(isLive ? 0.42 : 0.28),
                blurRadius: 28,
                spreadRadius: isLive ? 1 : 0,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ----- Full-bleed cover -----
                coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, prog) => prog == null
                            ? child
                            : _bannerFallback(accent, accentLight, isBlind),
                        errorBuilder: (_, __, ___) => _bannerFallback(accent, accentLight, isBlind),
                      )
                    : _bannerFallback(accent, accentLight, isBlind),

                // Legibility scrim: subtle at top, deep at the bottom.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.35, 1.0],
                        colors: [
                          Color(0x66000000),
                          Color(0x22000000),
                          Color(0xF2000000),
                        ],
                      ),
                    ),
                  ),
                ),

                // Live accent glow at the bottom for live events.
                if (isLive)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, accent.withOpacity(0.28)],
                        ),
                      ),
                    ),
                  ),

                // ----- Overlay content -----
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _glassPill(
                            icon: isBlind ? Icons.visibility_off_rounded : Icons.videocam_rounded,
                            label: isBlind ? 'Blind Date' : 'Speed Dating',
                            tint: accentLight,
                          ),
                          const Spacer(),
                          isLive ? _liveBadge(accent) : _countdownBadge(event),
                        ],
                      ),
                      const Spacer(),
                      _glassPanel(
                        event: event,
                        isBlind: isBlind,
                        isLive: isLive,
                        isFull: isFull,
                        cost: cost,
                        capacity: capacity,
                        booked: booked,
                        spotsLeft: spotsLeft,
                        myStatus: myStatus,
                        attendees: attendees,
                        accent: accent,
                        accentLight: accentLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted-glass info panel that floats over the bottom of the cover.
  Widget _glassPanel({
    required Map event,
    required bool isBlind,
    required bool isLive,
    required bool isFull,
    required int cost,
    required int capacity,
    required int booked,
    required int spotsLeft,
    required String? myStatus,
    required List attendees,
    required Color accent,
    required Color accentLight,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event['title']?.toString() ?? 'Live Date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.1),
              ),
              if ((event['description']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  event['description'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.78), fontSize: 12.5, height: 1.35),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _attendeeStack(attendees, booked, isBlind, accentLight),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFull
                              ? 'Full · waitlist open'
                              : '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left',
                          style: GoogleFonts.poppins(
                              color: isFull ? accentLight : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        _capacityBar(booked, capacity, accentLight),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  if (cost > 0)
                    _costChip(icon: Icons.diamond, label: '$cost', color: AppTheme.accent)
                  else
                    _costChip(icon: Icons.celebration_rounded, label: 'Free', color: const Color(0xFF34C759)),
                  const SizedBox(width: 10),
                  Expanded(child: _ctaButton(event, isLive, isFull, myStatus, accent, accentLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback(Color a, Color b, bool isBlind) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [a, b],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isBlind ? Icons.favorite_rounded : Icons.video_camera_front_rounded,
          color: Colors.white.withOpacity(0.85),
          size: 52,
        ),
      ),
    );
  }

  /// Frosted pill for the format badge over the cover.
  Widget _glassPill({required IconData icon, required String label, required Color tint}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.32),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: tint, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _costChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color == const Color(0xFF34C759) ? color : AppTheme.accentBright, size: 15),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _liveBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(color: Colors.white, size: 7),
          const SizedBox(width: 7),
          Text('LIVE NOW',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _countdownBadge(Map event) {
    final label = _countdownLabel(event['startsAt']?.toString());
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white, size: 13),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  String _countdownLabel(String? startsAt) {
    if (startsAt == null) return 'Soon';
    final start = DateTime.tryParse(startsAt)?.toLocal();
    if (start == null) return 'Soon';
    final diff = start.difference(DateTime.now());
    if (diff.isNegative) return 'Starting';
    if (diff.inDays >= 1) return 'in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours >= 1) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;
    return 'in ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _attendeeStack(List attendees, int total, bool isBlind, Color accent) {
    if (isBlind || attendees.isEmpty) {
      // Anonymous count chip for blind dates / no photos.
      return Container(
        width: 54,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_rounded, size: 14, color: accent),
            const SizedBox(width: 3),
            Text('$total', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final shown = attendees.take(3).toList();
    final extra = total - shown.length;
    return SizedBox(
      width: 24.0 * shown.length + (extra > 0 ? 24 : 0) + 12,
      height: 36,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 22.0,
              child: _avatar(_fullUrl(shown[i].toString())),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * 22.0,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                ),
                child: Text('+$extra',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(String url) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
        color: Colors.white.withOpacity(0.12),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? const Icon(Icons.person, color: Colors.white70, size: 18)
            : Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white70, size: 18)),
      ),
    );
  }

  Widget _capacityBar(int booked, int capacity, Color accent) {
    final pct = capacity == 0 ? 0.0 : (booked / capacity).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 6,
        backgroundColor: Colors.white.withOpacity(0.22),
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }

  Widget _ctaButton(
      Map event, bool isLive, bool isFull, String? myStatus, Color accent, Color accentLight) {
    final id = event['id'].toString();
    final busy = _busy.contains(id);
    final booked = myStatus == 'BOOKED' || myStatus == 'ATTENDED';
    final waitlisted = myStatus == 'WAITLISTED';

    if (busy) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: PremiumLoader(strokeWidth: 2.5, color: Colors.white),
          ),
        ),
      );
    }

    String label;
    IconData icon;
    List<Color> gradient;
    bool glass = false; // frosted style for secondary states
    VoidCallback? onTap;

    if (isLive && booked) {
      label = 'Join Room';
      icon = Icons.videocam_rounded;
      gradient = [accent, accentLight];
      onTap = () => context.push('/live-room', extra: {
            'eventId': event['id'].toString(),
            'eventTitle': event['title']?.toString() ?? 'Live Date',
            'audioOnly': (event['type']?.toString() == 'BLIND_DATE'),
          });
    } else if (booked) {
      label = 'Booked · Tap to cancel';
      icon = Icons.check_circle_rounded;
      gradient = [const Color(0xFF2FA84F), const Color(0xFF48C96B)];
      onTap = () => _cancel(event);
    } else if (waitlisted) {
      label = 'On waitlist · Leave';
      icon = Icons.hourglass_top_rounded;
      gradient = const [Colors.transparent, Colors.transparent];
      glass = true;
      onTap = () => _cancel(event);
    } else if (isFull) {
      label = 'Join Waitlist';
      icon = Icons.playlist_add_rounded;
      gradient = const [Colors.transparent, Colors.transparent];
      glass = true;
      onTap = () => _book(event);
    } else {
      label = 'Book Your Spot';
      icon = Icons.favorite_rounded;
      gradient = [accent, accentLight];
      onTap = () => _book(event);
    }

    final child = Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: glass ? null : LinearGradient(colors: gradient),
        color: glass ? Colors.white.withOpacity(0.14) : null,
        borderRadius: BorderRadius.circular(15),
        border: glass ? Border.all(color: Colors.white.withOpacity(0.28)) : null,
        boxShadow: glass
            ? null
            : [
                BoxShadow(
                  color: gradient.first.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ],
      ),
    );

    return _PressableScale(onTap: onTap, scale: 0.96, child: child);
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: PremiumLoader());

    // Empty state: full-bleed animated dating collage (manages its own
    // "check for events" action, so it lives outside the RefreshIndicator).
    if (_error == null && _events.isEmpty) {
      return LiveDatesCollage(onRefresh: _load);
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface(context),
      onRefresh: _load,
      child: _error != null ? _buildError() : _buildEventList(),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.textFaint(context)),
              const SizedBox(height: 16),
              Text('Couldn\'t load events',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary(context), fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _load,
                child: Text('Retry', style: GoogleFonts.poppins(color: AppTheme.accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small dot that gently pulses — used for LIVE indicators.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1
        return SizedBox(
          width: widget.size + 8,
          height: widget.size + 8,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding halo
                Container(
                  width: widget.size + t * 8,
                  height: widget.size + t * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.35 * (1 - t)),
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wraps a child so it scales down slightly while pressed — a tactile feel for
/// cards and buttons. A null [onTap] disables the interaction (no scale).
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, this.onTap, this.scale = 0.98});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A one-shot fade + slide-up entrance for list items, staggered by [delayMs].
class _EntranceFade extends StatefulWidget {
  const _EntranceFade({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fade);
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
