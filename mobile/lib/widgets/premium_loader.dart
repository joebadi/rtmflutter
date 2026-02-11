import 'package:flutter/material.dart';

/// Premium orange loading indicator to replace CircularProgressIndicator
class PremiumLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const PremiumLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? const Color(0xFFFF6B35),
        ),
      ),
    );
  }
}

/// Full-screen premium loading overlay with pulsing dots
class PremiumLoadingOverlay extends StatelessWidget {
  const PremiumLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: _PremiumLoadingDots(),
      ),
    );
  }
}

/// Premium bouncing dots loader
class _PremiumLoadingDots extends StatefulWidget {
  const _PremiumLoadingDots();

  @override
  State<_PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}

class _PremiumLoadingDotsState extends State<_PremiumLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final bounce = (progress < 0.5)
                ? Curves.easeOut.transform(progress * 2)
                : Curves.easeIn.transform((1 - progress) * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -8 * bounce),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFFFF6B35).withOpacity(0.4),
                      const Color(0xFFFF6B35),
                      bounce,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3 * bounce),
                        blurRadius: 8,
                        spreadRadius: 2 * bounce,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
