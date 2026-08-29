import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/verification_service.dart';
import '../../widgets/premium_loader.dart';
import '../../widgets/premium_message.dart';

/// Apply for Verification — upload a live selfie + a government ID, which is
/// queued for admin review. On approval the user receives a verified badge.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  final VerificationService _service = VerificationService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _existing;
  XFile? _selfie;
  XFile? _idDoc;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late AnimationController _selfieSuccessCtrl;
  late AnimationController _idSuccessCtrl;
  late Animation<double> _selfieCheck;
  late Animation<double> _idCheck;

  @override
  void initState() {
    super.initState();
    _load();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _selfieSuccessCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _idSuccessCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _selfieCheck = CurvedAnimation(
        parent: _selfieSuccessCtrl, curve: Curves.elasticOut);
    _idCheck =
        CurvedAnimation(parent: _idSuccessCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _selfieSuccessCtrl.dispose();
    _idSuccessCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final v = await _service.getStatus();
    if (!mounted) return;
    setState(() {
      _existing = v;
      _loading = false;
    });
  }

  String get _status =>
      (_existing?['status'] ?? '').toString().toUpperCase();

  Future<void> _pick(bool isSelfie) async {
    final file = await _picker.pickImage(
      source: isSelfie ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice:
          isSelfie ? CameraDevice.front : CameraDevice.rear,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file != null && mounted) {
      setState(() => isSelfie ? _selfie = file : _idDoc = file);
      if (isSelfie) {
        _selfieSuccessCtrl.forward(from: 0);
        _pulseCtrl.stop();
      } else {
        _idSuccessCtrl.forward(from: 0);
      }
    }
  }

  void _retakeSelfie() {
    setState(() => _selfie = null);
    _selfieSuccessCtrl.reset();
    _pulseCtrl.repeat();
  }

  Future<void> _submit() async {
    if (_selfie == null || _idDoc == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final ok = await _service.submit(
          selfiePath: _selfie!.path, idPath: _idDoc!.path);
      if (!mounted) return;
      if (ok) {
        await showPremiumAlert(
          context,
          title: 'Documents submitted',
          message: 'Your selfie and ID are under review — '
              'this usually takes 24–48 hours.',
          kind: MessageKind.success,
          autoDismiss: const Duration(milliseconds: 2000),
        );
        await _load();
      } else {
        await showPremiumAlert(
          context,
          title: 'Submission failed',
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
        message: 'Check your connection and try again.',
        kind: MessageKind.error,
        buttonText: 'Dismiss',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final showForm = _status != 'PENDING' && _status != 'APPROVED';
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Get Verified',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: PremiumLoader())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroBanner(),
                        const SizedBox(height: 24),
                        if (_status == 'PENDING') ...[
                          _statusCard(
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFFFB300),
                            title: 'Under review',
                            subtitle:
                                'Your documents have been submitted and are being reviewed. '
                                'This usually takes 24–48 hours.',
                          ),
                        ] else if (_status == 'APPROVED') ...[
                          _statusCard(
                            icon: Icons.verified_rounded,
                            color: const Color(0xFF34C759),
                            title: 'You\'re verified',
                            subtitle:
                                'Your profile now carries the verified badge. '
                                'Thanks for keeping the community trusted.',
                            showDone: true,
                          ),
                        ] else if (_status == 'REJECTED') ...[
                          _statusCard(
                            icon: Icons.cancel_rounded,
                            color: const Color(0xFFFF3B30),
                            title: 'Not approved',
                            subtitle: (_existing?['reviewNotes'] ??
                                    'Your documents could not be verified. '
                                        'Please re-submit clearer images.')
                                .toString(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (showForm) ...[
                          _stepSection(),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showForm) _footer(bottom),
              ],
            ),
    );
  }

  // ── Hero Banner ──────────────────────────────────────────────────────────

  Widget _heroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.18),
            AppTheme.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppTheme.accent.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        children: [
          // Shield icon with glow
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Build Trust & Get More Matches',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A quick selfie and government ID gets you the verified badge — '
            'showing your matches you\'re genuine.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _benefitChip(Icons.workspace_premium_rounded, 'Verified badge'),
              _benefitChip(Icons.favorite_rounded, 'More matches'),
              _benefitChip(Icons.shield_rounded, 'Trusted'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Card ──────────────────────────────────────────────────────────

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool showDone = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.5,
            ),
          ),
          if (showDone) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.pop(),
                    child: Center(
                      child: Text(
                        'Back to Options',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step Section ─────────────────────────────────────────────────────────

  Widget _stepSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(1, 'Take a live selfie', 'Front-facing camera'),
        const SizedBox(height: 12),
        _selfieCard(),
        const SizedBox(height: 24),
        _stepHeader(2, 'Upload a government ID',
            'Driver\'s licence, national ID, or passport'),
        const SizedBox(height: 12),
        _idCard(),
        const SizedBox(height: 16),
        _privacyNote(),
      ],
    );
  }

  Widget _stepHeader(int n, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$n',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Selfie Card ───────────────────────────────────────────────────────────

  Widget _selfieCard() {
    final size = MediaQuery.of(context).size.width - 40;
    final circleSize = size * 0.5;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _selfie != null
              ? AppTheme.accent.withValues(alpha: 0.5)
              : AppTheme.hairline(context),
          width: _selfie != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: circleSize + 36,
              height: circleSize + 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing outer ring
                  if (_selfie == null)
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: circleSize + 18,
                          height: circleSize + 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accent.withValues(
                                  alpha: _pulseOpacity.value),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Gradient ring
                  Container(
                    width: circleSize + 8,
                    height: circleSize + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        AppTheme.accent.withValues(alpha: 0.7),
                        AppTheme.accent.withValues(alpha: 0.1),
                        AppTheme.accent.withValues(alpha: 0.7),
                      ]),
                    ),
                  ),
                  // Photo or empty
                  GestureDetector(
                    onTap: _selfie != null ? null : () => _pick(true),
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface2(context),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.18),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selfie != null
                          ? Image.file(File(_selfie!.path), fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (r) =>
                                      AppTheme.accentGradient.createShader(r),
                                  child: Icon(
                                    Icons.face_retouching_natural_rounded,
                                    size: circleSize * 0.36,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Open camera',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  // Check badge
                  if (_selfie != null)
                    ScaleTransition(
                      scale: _selfieCheck,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 8, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.surface(context),
                                  width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF34C759)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_selfie != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _retakeSelfie,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 14, color: AppTheme.accent),
                  const SizedBox(width: 5),
                  Text(
                    'Retake selfie',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Look straight at the camera in good lighting',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── ID Card ───────────────────────────────────────────────────────────────

  Widget _idCard() {
    return GestureDetector(
      onTap: () => _pick(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _idDoc != null
                ? AppTheme.accent.withValues(alpha: 0.5)
                : AppTheme.hairline(context),
            width: _idDoc != null ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _idDoc != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(_idDoc!.path), fit: BoxFit.cover),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  // Change label
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Row(
                      children: [
                        const Icon(Icons.refresh_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Tap to change',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Check badge
                  Positioned(
                    right: 10,
                    top: 10,
                    child: ScaleTransition(
                      scale: _idCheck,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34C759)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_rounded,
                        size: 30, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload ID document',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to choose from gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _privacyNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_rounded, size: 12, color: AppTheme.textFaint(context)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Your documents are used only for verification and are never shown publicly.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textFaint(context),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer CTA ────────────────────────────────────────────────────────────

  Widget _footer(double bottomInset) {
    final ready = _selfie != null && _idDoc != null && !_submitting;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        border: Border(top: BorderSide(color: AppTheme.hairline(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: [
              _progressDot(_selfie != null),
              Expanded(
                child: Container(
                  height: 2,
                  color: _selfie != null && _idDoc != null
                      ? AppTheme.accent
                      : AppTheme.fg(context, 0.1),
                ),
              ),
              _progressDot(_idDoc != null),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selfie != null ? 'Selfie ✓' : 'Selfie',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _selfie != null
                      ? AppTheme.accent
                      : AppTheme.textFaint(context),
                ),
              ),
              Text(
                _idDoc != null ? 'ID ✓' : 'ID document',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _idDoc != null
                      ? AppTheme.accent
                      : AppTheme.textFaint(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
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
                  onTap: ready ? _submit : null,
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: PremiumLoader(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 18,
                                color: ready
                                    ? Colors.white
                                    : AppTheme.textFaint(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Submit for review',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ready
                                      ? Colors.white
                                      : AppTheme.textFaint(context),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressDot(bool done) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppTheme.accent : AppTheme.fg(context, 0.12),
        boxShadow: done
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 6,
                )
              ]
            : null,
      ),
    );
  }
}
