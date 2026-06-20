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

/// Show a premium centered alert dialog with an animated icon badge, title and
/// message. More substantial than a snackbar — use it for save confirmations,
/// errors, and other moments that deserve a beat of attention.
///
/// When [autoDismiss] is set, the dialog closes itself after that duration
/// (handy for success confirmations). The returned future completes once the
/// dialog is gone, so callers can navigate afterwards.
Future<void> showPremiumAlert(
  BuildContext context, {
  required String title,
  String? message,
  MessageKind kind = MessageKind.success,
  String buttonText = 'Got it',
  Duration? autoDismiss,
}) {
  final style = _styleFor(kind);
  return showGeneralDialog(
    context: context,
    barrierDismissible: autoDismiss == null,
    barrierLabel: title,
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0));
      if (autoDismiss != null && anim.value == 1) {
        final navigator = Navigator.of(ctx);
        Future.delayed(autoDismiss, () {
          if (navigator.canPop()) navigator.pop();
        });
      }
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Center(
          child: Transform.scale(
            scale: 0.85 + 0.15 * curved,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: style.color.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: style.color.withOpacity(0.18),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          style.color.withOpacity(0.30),
                          style.color.withOpacity(0.10),
                        ],
                      ),
                    ),
                    child: Icon(style.icon, color: style.color, size: 34),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.66),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (autoDismiss == null) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Center(
                              child: Text(
                                buttonText,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
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
            ),
          ),
        ),
      );
    },
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
