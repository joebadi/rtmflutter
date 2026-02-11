import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_loader.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    this.email,
    this.firstName,
    this.lastName,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _canResend = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _resendOtp() async {
    final auth = context.read<AuthProvider>();
    final emailOrPhone = widget.email ?? widget.phoneNumber;
    final success = await auth.sendOtp(emailOrPhone);

    if (!mounted) return;

    if (success) {
      setState(() {
        _canResend = false;
        _resendTimer = 60;
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Call backend API to verify OTP
    final auth = context.read<AuthProvider>();
    final emailOrPhone = widget.email ?? widget.phoneNumber;
    final success = await auth.verifyOtp(emailOrPhone, otp);

    if (!mounted) return;

    if (success) {
      _showResultPopup(
        isSuccess: true,
        title: 'Verified!',
        message: 'Your account has been verified successfully.',
        onDismiss: () {
          if (mounted) {
            context.go(
              '/profile-details',
              extra: {'firstName': widget.firstName, 'lastName': widget.lastName},
            );
          }
        },
      );
    } else {
      _showResultPopup(
        isSuccess: false,
        title: 'Verification Failed',
        message: auth.error ?? 'The OTP you entered is incorrect. Please try again.',
      );
    }
  }

  void _showResultPopup({
    required bool isSuccess,
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: !isSuccess,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curvedAnim,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon container
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 44,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDismiss?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccess
                            ? const Color(0xFFFF6B35)
                            : Colors.grey[200],
                        foregroundColor: isSuccess ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSuccess ? 'Continue' : 'Try Again',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Auto-dismiss success popup after 2 seconds
    if (isSuccess) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          onDismiss?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify Your Account',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Step 5 of 5',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF6B35,
                                    ).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mail_outline,
                                    size: 40,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Title
                                Text(
                                  'Enter Verification Code',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.email != null
                                      ? 'We\'ve sent a 6-digit code to\n${widget.email}'
                                      : 'We\'ve sent a 6-digit code to\n${widget.phoneNumber}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // OTP Input Fields
                                Flexible(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(6, (index) {
                                      return Flexible(
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 50,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 0.85,
                                            child: TextField(
                                              controller:
                                                  _otpControllers[index],
                                              focusNode: _focusNodes[index],
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              decoration: InputDecoration(
                                                counterText: '',
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding: EdgeInsets.zero,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFFF6B35,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (value) {
                                                if (value.isNotEmpty &&
                                                    index < 5) {
                                                  _focusNodes[index + 1]
                                                      .requestFocus();
                                                } else if (value.isEmpty &&
                                                    index > 0) {
                                                  _focusNodes[index - 1]
                                                      .requestFocus();
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Resend Code
                                _canResend
                                    ? TextButton(
                                        onPressed: _resendOtp,
                                        child: Text(
                                          'Resend Code',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFFFF6B35),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Resend code in $_resendTimer seconds',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 13,
                                        ),
                                      ),

                                const Spacer(),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : _verifyOTP,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B35),
                                      disabledBackgroundColor: const Color(
                                        0xFFFF6B35,
                                      ).withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: PremiumLoader(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'Verify & Complete',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
