import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../services/live_call_service.dart';
import '../../widgets/premium_loader.dart';

/// A 1:1 Live Dates call.
///
/// - Speed Dating → video call (local PiP + remote full-screen).
/// - Blind Date  → audio only; the partner is shown as a blurred/obscured
///   avatar with their name, never their photo.
class LiveCallScreen extends StatefulWidget {
  final String channelName;
  final String partnerName;
  final bool audioOnly;

  const LiveCallScreen({
    super.key,
    required this.channelName,
    this.partnerName = 'Your date',
    this.audioOnly = false,
  });

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> {
  final LiveCallService _callService = LiveCallService();

  RtcEngine? _engine;
  bool _localJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoOff = false;
  String? _error;
  String? _appId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Permissions
      final perms = widget.audioOnly
          ? [Permission.microphone]
          : [Permission.microphone, Permission.camera];
      final statuses = await perms.request();
      if (statuses.values.any((s) => !s.isGranted)) {
        setState(() => _error = 'Camera/microphone permission is required for live dates.');
        return;
      }

      // 2. Token from backend
      final data = await _callService.getRtcToken(widget.channelName);
      _appId = data['appId']?.toString();
      final token = data['token']?.toString() ?? '';
      final uid = (data['uid'] ?? 0) as int;

      if (_appId == null || _appId!.isEmpty) {
        setState(() => _error = 'Live calling is not configured yet.');
        return;
      }

      // 3. Engine
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: _appId));
      _engine = engine;

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (mounted) setState(() => _localJoined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (mounted) setState(() => _remoteUid = null);
          },
          onError: (err, msg) {
            debugPrint('[LiveCall] Agora error: $err $msg');
          },
        ),
      );

      await engine.enableAudio();
      if (!widget.audioOnly) {
        await engine.enableVideo();
        await engine.startPreview();
      }

      await engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: !widget.audioOnly,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: !widget.audioOnly,
        ),
      );
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('AGORA_NOT_CONFIGURED')
          ? 'Live calling is not configured on the server yet.'
          : msg.replaceAll('Exception: ', ''));
    }
  }

  Future<void> _cleanup() async {
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
    }
  }

  Future<void> _hangUp() async {
    await _cleanup();
    if (mounted) context.pop();
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

  void _switchCamera() => _engine?.switchCamera();

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildStage(),
            // Top bar
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.audioOnly ? Icons.mic_rounded : Icons.videocam_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(widget.partnerName,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_remoteUid != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.green, borderRadius: BorderRadius.circular(20)),
                      child: Text('Connected',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            // Controls
            Positioned(left: 0, right: 0, bottom: 28, child: _buildControls()),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    if (_error != null) return _buildError();
    if (!_localJoined) {
      return const Center(child: PremiumLoader());
    }

    // Audio-only (Blind Date): obscured avatar, no video at all.
    if (widget.audioOnly) {
      return _buildAudioStage();
    }

    // Video: remote full-screen + local PiP.
    return Stack(
      children: [
        Positioned.fill(child: _remoteUid != null ? _remoteVideo() : _waitingForPartner()),
        Positioned(
          top: 60,
          right: 16,
          child: Container(
            width: 110,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _videoOff
                ? Container(
                    color: AppTheme.darkSurface2,
                    child: const Center(child: Icon(Icons.videocam_off, color: Colors.white38)),
                  )
                : AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _remoteVideo() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _waitingForPartner() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.accentGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            Text('Waiting for ${widget.partnerName}…',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioStage() {
    final connected = _remoteUid != null;
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
            // Obscured avatar — identity hidden until unveiled.
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.visibility_off_rounded, color: Colors.white70, size: 64),
            ),
            const SizedBox(height: 24),
            Text(widget.partnerName,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(connected ? 'Connected · say hello 👋' : 'Connecting…',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Photos stay hidden until you both unveil',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrl(
          icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          bg: _muted ? Colors.white : Colors.white24,
          fg: _muted ? Colors.black : Colors.white,
          onTap: _toggleMute,
        ),
        const SizedBox(width: 18),
        if (!widget.audioOnly) ...[
          _ctrl(
            icon: _videoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
            bg: _videoOff ? Colors.white : Colors.white24,
            fg: _videoOff ? Colors.black : Colors.white,
            onTap: _toggleVideo,
          ),
          const SizedBox(width: 18),
          _ctrl(icon: Icons.cameraswitch_rounded, bg: Colors.white24, fg: Colors.white, onTap: _switchCamera),
          const SizedBox(width: 18),
        ],
        _ctrl(icon: Icons.call_end_rounded, bg: Colors.red, fg: Colors.white, onTap: _hangUp, big: true),
      ],
    );
  }

  Widget _ctrl({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    bool big = false,
  }) {
    final size = big ? 64.0 : 54.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: big ? 30 : 26),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(_error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () => context.pop(),
              child: Text('Back', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
