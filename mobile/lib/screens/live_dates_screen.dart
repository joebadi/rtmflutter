import 'dart:async';
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
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel booking?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Your diamonds will be refunded if the event hasn\'t started.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it', style: GoogleFonts.poppins(color: Colors.white54)),
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
      _toast('Booking cancelled.', AppTheme.darkSurface2);
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
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: AppTheme.accent, size: 48),
              const SizedBox(height: 16),
              Text('Not enough diamonds',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '"${event['title']}" costs ${event['diamondCost']} diamonds to join. Top up to book your spot.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5),
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
                child: Text('Maybe later', style: GoogleFonts.poppins(color: Colors.white38)),
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
      backgroundColor: AppTheme.darkBg,
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
                const AppLogo(height: 20, color: Colors.white),
                const SizedBox(height: 8),
                Text('Live Dates',
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  liveCount > 0
                      ? '$liveCount event${liveCount > 1 ? 's' : ''} live right now'
                      : 'Meet someone face-to-face',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: liveCount > 0 ? AppTheme.accentBright : Colors.white54),
                ),
              ],
            ),
          ),
          // Diamond balance chip
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
          const SizedBox(width: 4),
          const NotificationIcon(isDark: true),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _events.length,
      itemBuilder: (context, index) => _buildEventCard(_events[index] as Map),
    );
  }

  Widget _buildEventCard(Map event) {
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
    final attendees = (event['attendeePreview'] as List?) ?? [];
    final coverUrl = _fullUrl(event['coverImageUrl']?.toString());

    final accent = isBlind ? const Color(0xFF7E57C2) : AppTheme.accent;
    final accentLight = isBlind ? const Color(0xFF9575CD) : AppTheme.accentLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkSurface, AppTheme.darkSurface2],
        ),
        border: Border.all(
          color: isLive ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.07),
          width: isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? accent : Colors.black).withOpacity(isLive ? 0.3 : 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Cover / banner -----
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _bannerFallback(accent, accentLight, isBlind),
                        )
                      : _bannerFallback(accent, accentLight, isBlind),
                ),
                // dark gradient for text legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.darkSurface.withOpacity(0.95)],
                      ),
                    ),
                  ),
                ),
                // Format badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: _pill(
                    icon: isBlind ? Icons.visibility_off_rounded : Icons.videocam_rounded,
                    label: isBlind ? 'Blind Date · Audio' : 'Speed Dating · Video',
                    color: accent,
                  ),
                ),
                // Live / countdown badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: isLive ? _liveBadge(accent) : _countdownBadge(event),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title']?.toString() ?? 'Live Date',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  if ((event['description']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(event['description'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13, height: 1.4)),
                  ],
                  const SizedBox(height: 14),

                  // Attendees + capacity
                  Row(
                    children: [
                      _attendeeStack(attendees, booked, isBlind, accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFull ? 'Full · waitlist open' : '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left',
                              style: GoogleFonts.poppins(
                                  color: isFull ? AppTheme.accentBright : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            _capacityBar(booked, capacity, accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cost + CTA
                  Row(
                    children: [
                      if (cost > 0)
                        _pill(icon: Icons.diamond, label: '$cost', color: AppTheme.accent)
                      else
                        _pill(icon: Icons.celebration_rounded, label: 'Free', color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(child: _ctaButton(event, isLive, isFull, myStatus, accent)),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          size: 46,
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _liveBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('LIVE NOW',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _countdownBadge(Map event) {
    final label = _countdownLabel(event['startsAt']?.toString());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
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
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_rounded, size: 14, color: accent),
            const SizedBox(width: 3),
            Text('$total', style: GoogleFonts.poppins(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
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
                  color: AppTheme.darkSurface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.darkBg, width: 2),
                ),
                child: Text('+$extra',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
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
        border: Border.all(color: AppTheme.darkBg, width: 2),
        color: AppTheme.darkSurface2,
      ),
      child: ClipOval(
        child: url.isEmpty
            ? const Icon(Icons.person, color: Colors.white30, size: 18)
            : Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white30, size: 18)),
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
        backgroundColor: Colors.white.withOpacity(0.08),
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }

  Widget _ctaButton(Map event, bool isLive, bool isFull, String? myStatus, Color accent) {
    final id = event['id'].toString();
    final busy = _busy.contains(id);
    final booked = myStatus == 'BOOKED' || myStatus == 'ATTENDED';
    final waitlisted = myStatus == 'WAITLISTED';

    String label;
    IconData icon;
    Color bg;
    VoidCallback? onTap;

    if (busy) {
      return SizedBox(
        height: 46,
        child: Center(
          child: SizedBox(
            width: 22, height: 22,
            child: PremiumLoader(strokeWidth: 2.5, color: accent),
          ),
        ),
      );
    }

    if (isLive && booked) {
      label = 'Join Room';
      icon = Icons.videocam_rounded;
      bg = accent;
      onTap = () => context.push('/live-room', extra: {
            'eventId': event['id'].toString(),
            'eventTitle': event['title']?.toString() ?? 'Live Date',
            'audioOnly': (event['type']?.toString() == 'BLIND_DATE'),
          });
    } else if (booked) {
      label = 'Booked · Tap to cancel';
      icon = Icons.check_circle_rounded;
      bg = Colors.green.shade600;
      onTap = () => _cancel(event);
    } else if (waitlisted) {
      label = 'On waitlist · Leave';
      icon = Icons.hourglass_top_rounded;
      bg = AppTheme.darkSurface2;
      onTap = () => _cancel(event);
    } else if (isFull) {
      label = 'Join Waitlist';
      icon = Icons.playlist_add_rounded;
      bg = AppTheme.darkSurface2;
      onTap = () => _book(event);
    } else {
      label = 'Book a Slot';
      icon = Icons.bolt_rounded;
      bg = accent;
      onTap = () => _book(event);
    }

    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
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
      backgroundColor: AppTheme.darkSurface,
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
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white38),
              const SizedBox(height: 16),
              Text('Couldn\'t load events',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
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
