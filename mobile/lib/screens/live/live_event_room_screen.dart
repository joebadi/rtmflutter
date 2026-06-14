import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/live_service.dart';
import '../../providers/message_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/premium_loader.dart';

enum _Phase { lobby, inCall, interest, ended }

/// The full Live Dates event experience: a lobby that auto-launches each timed
/// 1:1 round (video, or audio for blind dates), prompts for interest + a rating
/// after every round, and shows a summary when the event ends. Round transitions
/// are pushed from the server over the shared socket.
class LiveEventRoomScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final bool audioOnly;

  const LiveEventRoomScreen({
    super.key,
    required this.eventId,
    this.eventTitle = 'Live Date',
    this.audioOnly = false,
  });

  @override
  State<LiveEventRoomScreen> createState() => _LiveEventRoomScreenState();
}

class _LiveEventRoomScreenState extends State<LiveEventRoomScreen> {
  final LiveService _live = LiveService();

  _Phase _phase = _Phase.lobby;
  int _round = 0;

  // Active pairing / call state
  Map<String, dynamic>? _pairing; // {pairingId, channelName, partner, audioOnly}
  RtcEngine? _engine;
  bool _localJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoOff = false;

  // Interest phase
  Map<String, dynamic>? _interestPartner;
  String? _interestPairingId;
  int _rating = 0;
  bool _interestBusy = false;

  int _matches = 0;
  String? _matchBanner;

  // Blind-date in-call unveil
  bool _unveilBusy = false;
  String? _revealedPhotoUrl; // set once the current partner is unveiled

  dynamic get _socket => context.read<MessageProvider>().socket;

  @override
  void initState() {
    super.initState();
    _setupSocket();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _live.joinLobby(widget.eventId);
      final state = await _live.getEventState(widget.eventId);
      if (!mounted) return;
      setState(() {
        _round = (state['roundNumber'] ?? 0) as int;
      });
      final mine = state['myPairing'];
      if (state['status'] == 'LIVE' && mine != null) {
        _startCall(Map<String, dynamic>.from(mine));
      } else if (state['status'] == 'POST_EVENT' || state['status'] == 'COMPLETED') {
        setState(() => _phase = _Phase.ended);
      }
    } catch (e) {
      debugPrint('[LiveRoom] bootstrap error: $e');
    }
  }

  void _setupSocket() {
    final s = _socket;
    if (s == null) return;
    s.on('live:round_start', (data) {
      if (!mounted) return;
      setState(() => _round = (data['roundNumber'] ?? _round) as int);
      _startCall(Map<String, dynamic>.from(data));
    });
    s.on('live:round_end', (data) {
      if (!mounted) return;
      _endCallToInterest();
    });
    s.on('live:sit_out', (data) {
      if (!mounted) return;
      setState(() {
        _round = (data['roundNumber'] ?? _round) as int;
        _phase = _Phase.lobby;
      });
    });
    s.on('live:event_ended', (data) {
      if (!mounted) return;
      setState(() => _matches = (data['matches'] ?? _matches) as int);
      _leaveAgora();
      setState(() => _phase = _Phase.ended);
    });
    s.on('live:matched', (data) {
      if (!mounted) return;
      final name = (data['partner']?['firstName'] ?? 'someone').toString();
      setState(() => _matchBanner = "It's a match with $name! 💖");
    });
  }

  void _teardownSocket() {
    final s = _socket;
    if (s == null) return;
    for (final ev in ['live:round_start', 'live:round_end', 'live:sit_out', 'live:event_ended', 'live:matched']) {
      s.off(ev);
    }
  }

  // ----- Agora call -----

  Future<void> _startCall(Map<String, dynamic> pairing) async {
    setState(() {
      _pairing = pairing;
      _phase = _Phase.inCall;
      _localJoined = false;
      _remoteUid = null;
      _muted = false;
      _videoOff = false;
      _unveilBusy = false;
      _revealedPhotoUrl = null;
    });

    final audioOnly = pairing['audioOnly'] == true || widget.audioOnly;
    try {
      final perms = audioOnly ? [Permission.microphone] : [Permission.microphone, Permission.camera];
      final statuses = await perms.request();
      if (statuses.values.any((s) => !s.isGranted)) return;

      final pairingId = pairing['pairingId'].toString();
      final data = await _live.getPairingToken(pairingId);
      final appId = data['appId']?.toString() ?? '';
      final token = data['token']?.toString() ?? '';
      final uid = (data['uid'] ?? 0) as int;
      if (appId.isEmpty) return;

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: appId));
      _engine = engine;
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (c, e) {
          if (mounted) setState(() => _localJoined = true);
        },
        onUserJoined: (c, remoteUid, e) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (c, remoteUid, r) {
          if (mounted) setState(() => _remoteUid = null);
        },
      ));

      await engine.enableAudio();
      if (!audioOnly) {
        await engine.enableVideo();
        await engine.startPreview();
      }
      await engine.joinChannel(
        token: token,
        channelId: pairing['channelName'].toString(),
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: !audioOnly,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: !audioOnly,
        ),
      );
    } catch (e) {
      debugPrint('[LiveRoom] startCall error: $e');
    }
  }

  Future<void> _leaveAgora() async {
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
    }
  }

  void _endCallToInterest() {
    final pairing = _pairing;
    _leaveAgora();
    if (pairing == null) {
      setState(() => _phase = _Phase.lobby);
      return;
    }
    setState(() {
      _interestPartner = pairing['partner'] != null
          ? Map<String, dynamic>.from(pairing['partner'])
          : null;
      _interestPairingId = pairing['pairingId'].toString();
      _rating = 0;
      _interestBusy = false;
      _phase = _Phase.interest;
      _pairing = null;
      _localJoined = false;
      _remoteUid = null;
    });
  }

  Future<void> _submitInterest(bool interested) async {
    if (_interestPairingId == null || _interestBusy) return;
    setState(() => _interestBusy = true);
    try {
      if (_rating > 0) await _live.ratePairing(_interestPairingId!, _rating);
      await _live.sendInterest(_interestPairingId!, interested);
    } catch (e) {
      debugPrint('[LiveRoom] interest error: $e');
    }
    if (mounted) setState(() => _phase = _Phase.lobby);
  }

  /// Spend an unveil to reveal the current blind-date partner mid-call.
  Future<void> _unveilInCall() async {
    final pairing = _pairing;
    if (pairing == null || _unveilBusy || _revealedPhotoUrl != null) return;
    final pairingId = pairing['pairingId']?.toString();
    if (pairingId == null) return;

    setState(() => _unveilBusy = true);
    try {
      final result = await _live.unveilPartner(pairingId);
      if (!mounted) return;
      if (result['diamondBalance'] != null) {
        context.read<WalletProvider>().setBalance(result['diamondBalance'] as int);
      }
      final photo = _fullUrl(result['partner']?['photoUrl']?.toString());
      setState(() {
        _revealedPhotoUrl = photo;
        // keep the partner card in sync so the interest screen shows the photo too
        if (_pairing?['partner'] is Map) {
          _pairing!['partner'] = Map<String, dynamic>.from(result['partner']);
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('INSUFFICIENT_DIAMONDS')) {
        context.read<WalletProvider>().refresh();
        _showUnveilTopUp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _unveilBusy = false);
    }
  }

  void _showUnveilTopUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Not enough diamonds',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Top up to reveal who you\'re talking to.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: GoogleFonts.poppins(color: Colors.white54)),
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

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine?.muteLocalAudioStream(_muted);
  }

  void _toggleVideo() {
    setState(() => _videoOff = !_videoOff);
    _engine?.muteLocalVideoStream(_videoOff);
    _engine?.enableLocalVideo(!_videoOff);
  }

  Future<void> _leaveEvent() async {
    await _leaveAgora();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _teardownSocket();
    _leaveAgora();
    super.dispose();
  }

  String _fullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.socketUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.inCall,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: SafeArea(
          child: Stack(
            children: [
              switch (_phase) {
                _Phase.lobby => _buildLobby(),
                _Phase.inCall => _buildCall(),
                _Phase.interest => _buildInterest(),
                _Phase.ended => _buildEnded(),
              },
              if (_matchBanner != null) _buildMatchBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBanner() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => setState(() => _matchBanner = null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.heart]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_matchBanner!,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.close, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----- Lobby -----
  Widget _buildLobby() {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: PremiumLoader(),
                ),
                const SizedBox(height: 28),
                Text(_round == 0 ? 'Waiting for the event to begin' : 'Get ready for the next round',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _round == 0
                        ? "Hang tight — we'll connect you with your first date the moment the host starts."
                        : "You'll be matched with someone new shortly. Stay on this screen.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ----- Call -----
  Widget _buildCall() {
    final pairing = _pairing;
    final audioOnly = pairing?['audioOnly'] == true || widget.audioOnly;
    final partner = pairing?['partner'] as Map?;
    final partnerName = (partner?['firstName'] ?? 'Your date').toString();

    return Stack(
      children: [
        Positioned.fill(
          child: !_localJoined
              ? const Center(child: PremiumLoader())
              : audioOnly
                  ? _audioStage(partnerName)
                  : (_remoteUid != null ? _remoteVideo(pairing!) : _waiting(partnerName)),
        ),
        if (!audioOnly && _localJoined)
          Positioned(
            top: 56,
            right: 16,
            child: Container(
              width: 104,
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24, width: 2),
                color: AppTheme.darkSurface2,
              ),
              child: _videoOff
                  ? const Center(child: Icon(Icons.videocam_off, color: Colors.white38))
                  : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
            ),
          ),
        Positioned(top: 12, left: 16, child: _roundPill(partnerName)),
        Positioned(left: 0, right: 0, bottom: 28, child: _callControls(audioOnly)),
      ],
    );
  }

  Widget _remoteVideo(Map pairing) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: pairing['channelName'].toString()),
      ),
    );
  }

  Widget _waiting(String name) => Container(
        decoration: const BoxDecoration(gradient: AppTheme.accentGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white70, size: 56),
              const SizedBox(height: 16),
              Text('Connecting to $name…',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _audioStage(String name) {
    final revealed = _revealedPhotoUrl != null && _revealedPhotoUrl!.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7E57C2), Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: revealed
                  ? Image.network(_revealedPhotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.white70, size: 64))
                  : const Icon(Icons.visibility_off_rounded, color: Colors.white70, size: 64),
            ),
            const SizedBox(height: 24),
            Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_remoteUid != null ? 'Connected · say hello 👋' : 'Connecting…',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            if (revealed)
              Text('Revealed · is it a vibe? 👀',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12))
            else
              Text('Photos stay hidden — see who you click with after',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 22),
            if (!revealed) _unveilPill(),
          ],
        ),
      ),
    );
  }

  Widget _unveilPill() {
    return GestureDetector(
      onTap: _unveilBusy ? null : _unveilInCall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_unveilBusy)
              const SizedBox(
                width: 18, height: 18,
                child: PremiumLoader(strokeWidth: 2.2, color: Colors.white),
              )
            else
              const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Unveil my date',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _roundPill(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
        child: Text('Round $_round · $name',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _callControls(bool audioOnly) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrl(_muted ? Icons.mic_off_rounded : Icons.mic_rounded, _muted ? Colors.white : Colors.white24,
            _muted ? Colors.black : Colors.white, _toggleMute),
        const SizedBox(width: 18),
        if (!audioOnly) ...[
          _ctrl(_videoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              _videoOff ? Colors.white : Colors.white24, _videoOff ? Colors.black : Colors.white, _toggleVideo),
          const SizedBox(width: 18),
          _ctrl(Icons.cameraswitch_rounded, Colors.white24, Colors.white, () => _engine?.switchCamera()),
        ],
      ],
    );
  }

  Widget _ctrl(IconData icon, Color bg, Color fg, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: 26),
        ),
      );

  // ----- Interest / rating -----
  Widget _buildInterest() {
    final name = (_interestPartner?['firstName'] ?? 'your date').toString();
    final photo = _fullUrl(_interestPartner?['photoUrl']?.toString());

    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white12,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: photo.isEmpty
                      ? const Icon(Icons.person, color: Colors.white38, size: 56)
                      : Image.network(photo, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white38, size: 56)),
                ),
                const SizedBox(height: 20),
                Text('How was your date with $name?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < _rating;
                    return IconButton(
                      onPressed: () => setState(() => _rating = i + 1),
                      icon: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: filled ? const Color(0xFFFFC107) : Colors.white30, size: 36),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text('Want to keep talking after the event?',
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _interestBusy ? null : () => _submitInterest(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        label: Text('Pass', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _interestBusy ? null : () => _submitInterest(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                        label: Text('Interested', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('They won\'t know if you pass.',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ----- Ended -----
  Widget _buildEnded() {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(gradient: AppTheme.accentGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 24),
                Text("That's a wrap!",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _matches > 0
                      ? 'You matched with $_matches ${_matches == 1 ? 'person' : 'people'}! Find them in your messages.'
                      : 'No matches this time — your next date could be the one.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => context.pushReplacement('/live-results', extra: {
                        'eventId': widget.eventId,
                        'eventTitle': widget.eventTitle,
                      }),
                      icon: const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                      label: Text('See your results',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/messages'),
                  child: Text('Go to Messages', style: GoogleFonts.poppins(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _leaveEvent,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(widget.eventTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
