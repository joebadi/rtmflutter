import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Premium feedback messages for auth (and elsewhere): a floating snackbar with
/// an icon, frosted dark surface and an accent edge, plus an inline banner for
/// persistent validation warnings.
enum MessageKind { error, warning, success, info }

class _MessageStyle {
  const _MessageStyle(this.color, this.icon);
  final Color color;
  final IconData icon;
}

_MessageStyle _styleFor(MessageKind kind) {
  switch (kind) {
    case MessageKind.error:
      return const _MessageStyle(Color(0xFFFF5252), Icons.error_outline_rounded);
    case MessageKind.warning:
      return const _MessageStyle(Color(0xFFFFB300), Icons.warning_amber_rounded);
    case MessageKind.success:
      return const _MessageStyle(Color(0xFF34C759), Icons.check_circle_outline_rounded);
    case MessageKind.info:
      return const _MessageStyle(AppTheme.accent, Icons.info_outline_rounded);
  }
}

/// Show a premium floating snackbar. Replaces plain red SnackBars.
void showPremiumSnack(
  BuildContext context,
  String message, {
  MessageKind kind = MessageKind.error,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final style = _styleFor(kind);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 3),
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: style.color.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Inline, animated warning banner for persistent validation messages.
/// Renders nothing (and collapses) when [message] is null.
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({
    super.key,
    required this.message,
    this.kind = MessageKind.error,
  });

  final String? message;
  final MessageKind kind;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(kind);
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SizeTransition(sizeFactor: anim, child: child),
        ),
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Container(
                key: ValueKey(message),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: style.color.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(style.icon, color: style.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
