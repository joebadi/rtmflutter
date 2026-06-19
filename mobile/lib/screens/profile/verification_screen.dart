import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/verification_service.dart';
import '../../widgets/premium_loader.dart';

/// Apply for Verification — upload a live selfie + a government ID, which is
/// queued for admin review. On approval the user receives a verified badge.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final VerificationService _service = VerificationService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _existing;
  XFile? _selfie;
  XFile? _idDoc;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _pick(bool selfie) async {
    final file = await _picker.pickImage(
      source: selfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file != null && mounted) {
      setState(() => selfie ? _selfie = file : _idDoc = file);
    }
  }

  Future<void> _submit() async {
    if (_selfie == null || _idDoc == null) return;
    setState(() => _submitting = true);
    try {
      final ok = await _service.submit(
          selfiePath: _selfie!.path, idPath: _idDoc!.path);
      if (!mounted) return;
      if (ok) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submitted for review',
                  style: GoogleFonts.poppins()),
              backgroundColor: AppTheme.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _error('Submission failed. Please try again.');
      }
    } catch (_) {
      _error('Submission failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _error(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(m, style: GoogleFonts.poppins()),
          backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showForm = _status != 'PENDING' && _status != 'APPROVED';
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary(context)),
        title: Text('Get Verified',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
      ),
      body: _loading
          ? const Center(child: PremiumLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_status == 'PENDING') _statusCard(
                      Icons.hourglass_top_rounded,
                      const Color(0xFFFFB300),
                      'Under review',
                      'Your documents were submitted and are being reviewed. This usually takes 24–48 hours.'),
                  if (_status == 'APPROVED') _statusCard(
                      Icons.verified_rounded,
                      const Color(0xFF34C759),
                      'You\'re verified',
                      'Your profile now carries the verified badge. Thanks for keeping the community trusted.'),
                  if (_status == 'REJECTED') _statusCard(
                      Icons.error_outline_rounded,
                      const Color(0xFFFF5252),
                      'Not approved',
                      (_existing?['reviewNotes'] ?? 'Your documents could not be verified. Please re-submit clearer images.')
                          .toString()),
                  if (showForm) ..._form(),
                ],
              ),
            ),
    );
  }

  List<Widget> _form() {
    return [
      if (_status == 'REJECTED') const SizedBox(height: 20),
      _hero(),
      const SizedBox(height: 22),
      Text('1. Take a live selfie',
          style: _label()),
      const SizedBox(height: 8),
      _pickTile(
        file: _selfie,
        icon: Icons.camera_alt_rounded,
        label: 'Open camera',
        onTap: () => _pick(true),
      ),
      const SizedBox(height: 20),
      Text('2. Upload a government ID',
          style: _label()),
      const SizedBox(height: 4),
      Text('Driver\'s licence, national ID, or passport.',
          style: GoogleFonts.poppins(
              fontSize: 11.5, color: AppTheme.textSecondary(context))),
      const SizedBox(height: 8),
      _pickTile(
        file: _idDoc,
        icon: Icons.badge_rounded,
        label: 'Choose image',
        onTap: () => _pick(false),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(Icons.lock_rounded,
              size: 13, color: AppTheme.textFaint(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Your documents are used only for verification and are never shown on your profile.',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textFaint(context), height: 1.4),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _submitButton(),
    ];
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.accent.withValues(alpha: 0.16),
          AppTheme.accent.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded,
                color: AppTheme.accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Get a verified badge so matches know you\'re the real deal.',
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppTheme.textPrimary(context),
                  height: 1.4,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickTile({
    required XFile? file,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: file != null
                  ? AppTheme.accent
                  : AppTheme.hairline(context),
              width: file != null ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(file.path), fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppTheme.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Tap to change',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 10.5)),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 34, color: AppTheme.accent),
                  const SizedBox(height: 8),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context))),
                ],
              ),
      ),
    );
  }

  Widget _submitButton() {
    final ready = _selfie != null && _idDoc != null && !_submitting;
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
            onTap: ready ? _submit : null,
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: PremiumLoader(strokeWidth: 2.4, color: Colors.white))
                  : Text('Submit for review',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ready
                              ? Colors.white
                              : AppTheme.textFaint(context))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard(
      IconData icon, Color color, String title, String subtitle) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                  height: 1.45)),
          if (_status == 'APPROVED') ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(14)),
                child: Text('Done',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _label() => GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary(context));
}
