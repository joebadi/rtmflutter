import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/verification_service.dart';
import '../../widgets/premium_loader.dart';
import '../../widgets/premium_message.dart';

/// Registration verification step — capture a live selfie and submit it for
/// admin review. On approval the user receives the verified badge.
class VideoVerificationPage extends StatefulWidget {
  const VideoVerificationPage({super.key});

  @override
  State<VideoVerificationPage> createState() => _VideoVerificationPageState();
}

class _VideoVerificationPageState extends State<VideoVerificationPage>
    with TickerProviderStateMixin {
  final VerificationService _service = VerificationService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selfie;
  bool _submitting = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: false);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file != null && mounted) {
        setState(() => _selfie = file);
        _successCtrl.forward(from: 0);
        _pulseCtrl.stop();
      }
    } catch (_) {
      if (mounted) {
        showPremiumSnack(
          context,
          'Couldn\'t open the camera. Please allow camera access.',
          kind: MessageKind.error,
        );
      }
    }
  }

  void _retake() {
    setState(() => _selfie = null);
    _successCtrl.reset();
    _pulseCtrl.repeat();
  }

  Future<void> _submit() async {
    if (_selfie == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final ok = await _service.submit(selfiePath: _selfie!.path);
      if (!mounted) return;
      if (ok) {
        await showPremiumAlert(
          context,
          title: 'Selfie submitted',
          message:
              'Your photo is under review — this usually takes 24–48 hours. '
              'You can keep setting up your profile in the meantime.',
          kind: MessageKind.success,
          autoDismiss: const Duration(milliseconds: 1800),
        );
        if (mounted) context.go('/complete-profile');
      } else {
        await showPremiumAlert(
          context,
          title: 'Couldn\'t submit',
          message: 'Please check your connection and try again.',
          kind: MessageKind.error,
          buttonText: 'Try again',
        );
      }
    } catch (_) {
      if (!mounted) return;
      await showPremiumAlert(
        context,
        title: 'Something went wrong',
        message: 'Please check your connection and try again.',
        kind: MessageKind.error,
        buttonText: 'Dismiss',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _skip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Skip verification?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        content: Text(
          'Verifying builds trust and unlocks the verified badge. You can '
          'always do this later from Options → Get Verified.',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppTheme.textSecondary(context),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/complete-profile');
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.poppins(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Column(
        children: [
          _header(),
          Expanded(child: _body()),
          _footer(bottom),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 12, 0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary(context),
              ),
              onPressed: () => context.pop(),
            ),
            Expanded(child: _stepDots()),
            TextButton(
              onPressed: _submitting ? null : _skip,
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i == 4;
        final done = i < 4;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? AppTheme.accent
                : done
                    ? AppTheme.accent.withValues(alpha: 0.35)
                    : AppTheme.fg(context, 0.12),
          ),
        );
      }),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _body() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _heroSection(),
          const SizedBox(height: 28),
          _infoSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────

  Widget _heroSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          children: [
            _selfiePicker(),
            const SizedBox(height: 22),
            _statusText(),
          ],
        ),
      ),
    );
  }

  Widget _selfiePicker() {
    final size = MediaQuery.of(context).size.width * 0.54;
    return Center(
      child: SizedBox(
        width: size + 40,
        height: size + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring — only when no selfie
            if (_selfie == null)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: _pulseScale.value,
                  child: Container(
                    width: size + 20,
                    height: size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accent.withValues(
                          alpha: _pulseOpacity.value * 0.8,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // Outer static ring
            Container(
              width: size + 12,
              height: size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.6),
                    AppTheme.accent.withValues(alpha: 0.1),
                    AppTheme.accent.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),

            // Main selfie circle
            GestureDetector(
              onTap: _submitting ? null : (_selfie != null ? null : _capture),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface2(context),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.22),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _selfie != null
                    ? Image.file(File(_selfie!.path), fit: BoxFit.cover)
                    : _emptyState(size),
              ),
            ),

            // Success check badge
            if (_selfie != null)
              ScaleTransition(
                scale: _successScale,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.surface(context),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(double size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Face silhouette guide
        ShaderMask(
          shaderCallback: (rect) => AppTheme.accentGradient.createShader(rect),
          child: Icon(
            Icons.face_retouching_natural_rounded,
            size: size * 0.38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded,
                  size: 13, color: AppTheme.accent),
              const SizedBox(width: 5),
              Text(
                'Tap to capture',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusText() {
    if (_selfie != null) {
      return Column(
        children: [
          Text(
            'Looking good!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _retake,
            child: Text(
              'Retake selfie',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.accent,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.accent,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Text(
          'Verify it\'s you',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a live selfie — it\'s never shown on your profile',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppTheme.textSecondary(context),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Info Section ─────────────────────────────────────────────────────────

  Widget _infoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips for a quick approval',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          _tipRow(Icons.wb_sunny_rounded, 'Good lighting — face a window or bright lamp'),
          const SizedBox(height: 8),
          _tipRow(Icons.crop_free_rounded, 'Keep your whole face clearly in frame'),
          const SizedBox(height: 8),
          _tipRow(Icons.visibility_rounded, 'Remove sunglasses, hats or face coverings'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_rounded, size: 12, color: AppTheme.textFaint(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your selfie is used only for identity verification and is never shown publicly.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textFaint(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: AppTheme.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer CTA ───────────────────────────────────────────────────────────

  Widget _footer(double bottomInset) {
    final ready = _selfie != null && !_submitting;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        border: Border(top: BorderSide(color: AppTheme.hairline(context))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ready ? AppTheme.accentGradient : null,
            color: ready ? null : AppTheme.surface2(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: ready
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: ready
                  ? _submit
                  : (_submitting ? null : _capture),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: PremiumLoader(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selfie == null) ...[
                            const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _selfie == null ? 'Take selfie' : 'Submit for review',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ready
                                  ? Colors.white
                                  : AppTheme.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
