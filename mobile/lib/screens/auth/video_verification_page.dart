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
/// admin review. On approval the user receives the verified badge. This reuses
/// the same `/verification` pipeline as the Options "Get Verified" screen, but
/// asks for a selfie only to keep onboarding friction low (a government ID can
/// be added later from Options).
class VideoVerificationPage extends StatefulWidget {
  const VideoVerificationPage({super.key});

  @override
  State<VideoVerificationPage> createState() => _VideoVerificationPageState();
}

class _VideoVerificationPageState extends State<VideoVerificationPage> {
  final VerificationService _service = VerificationService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selfie;
  bool _submitting = false;

  Future<void> _capture() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file != null && mounted) setState(() => _selfie = file);
    } catch (_) {
      if (mounted) {
        showPremiumSnack(context, 'Couldn’t open the camera. Please allow camera access.',
            kind: MessageKind.error);
      }
    }
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
          title: 'Couldn’t submit',
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
        title: Text('Skip verification?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
        content: Text(
          'Verifying builds trust and unlocks the verified badge. You can always '
          'do this later from Options → Get Verified.',
          style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppTheme.textSecondary(context),
              height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/complete-profile');
            },
            child: Text('Skip for now',
                style: GoogleFonts.poppins(
                    color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary(context)),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text('Step 5 of 5',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textFaint(context))),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _submitting ? null : _skip,
                    child: Text('Skip',
                        style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(context))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Verify it’s you',
                        style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context))),
                    const SizedBox(height: 8),
                    Text(
                      'Take a quick selfie so we know you’re real. It’s reviewed '
                      'by our team and never shown on your profile.',
                      style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: AppTheme.textSecondary(context),
                          height: 1.45),
                    ),
                    const SizedBox(height: 28),
                    _selfieCircle(),
                    const SizedBox(height: 28),
                    _tips(),
                    const SizedBox(height: 16),
                    _privacyNote(),
                    const SizedBox(height: 28),
                    _primaryButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────── pieces

  Widget _selfieCircle() {
    return Center(
      child: GestureDetector(
        onTap: _submitting ? null : _capture,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface(context),
            border: Border.all(
              color: _selfie != null
                  ? AppTheme.accent
                  : AppTheme.accent.withValues(alpha: 0.35),
              width: _selfie != null ? 2.4 : 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.18),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _selfie != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(_selfie!.path), fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 15),
                            const SizedBox(width: 6),
                            Text('Retake',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: AppTheme.accent, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text('Tap to take a selfie',
                        style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context))),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tips() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('For a quick approval',
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(height: 12),
          _tip('Face the camera in good lighting'),
          _tip('Keep your whole face in frame'),
          _tip('Remove sunglasses, hats or masks'),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 17, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                    height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _privacyNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_rounded, size: 13, color: AppTheme.textFaint(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your selfie is used only for verification and is never shown on '
            'your profile.',
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textFaint(context),
                height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton() {
    final ready = _selfie != null && !_submitting;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ready ? AppTheme.accentGradient : null,
          color: ready ? null : AppTheme.surface2(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: ready ? _submit : (_submitting ? null : _capture),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: PremiumLoader(
                          strokeWidth: 2.4, color: Colors.white))
                  : Text(
                      _selfie == null ? 'Take selfie' : 'Submit for review',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ready
                              ? Colors.white
                              : AppTheme.textPrimary(context))),
            ),
          ),
        ),
      ),
    );
  }
}
