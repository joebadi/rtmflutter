import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class PasswordStrengthIndicator extends StatefulWidget {
  final String password;
  final Function(bool isStrong)? onStrengthChanged;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.onStrengthChanged,
  });

  @override
  State<PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<PasswordStrengthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  int _score = 0;
  String _level = 'weak';
  List<String> _feedback = [];
  bool _isValid = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PasswordStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _calculateStrength();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _calculateStrength() {
    if (widget.password.isEmpty) {
      setState(() {
        _score = 0;
        _level = 'weak';
        _feedback = [];
        _isValid = false;
      });
      _updateAnimation(0.0);
      widget.onStrengthChanged?.call(false);
      return;
    }

    int score = 0;
    List<String> feedback = [];

    // Length scoring (0-40 points)
    if (widget.password.length < 8) {
      feedback.add('At least 8 characters');
    } else if (widget.password.length >= 8 && widget.password.length < 12) {
      score += 20;
    } else if (widget.password.length >= 12 && widget.password.length < 16) {
      score += 30;
    } else {
      score += 40;
    }

    // Uppercase letters (0-15 points)
    if (RegExp(r'[A-Z]').hasMatch(widget.password)) {
      score += 15;
    } else {
      feedback.add('Add uppercase letters');
    }

    // Lowercase letters (0-15 points)
    if (RegExp(r'[a-z]').hasMatch(widget.password)) {
      score += 15;
    } else {
      feedback.add('Add lowercase letters');
    }

    // Numbers (0-15 points)
    if (RegExp(r'[0-9]').hasMatch(widget.password)) {
      score += 15;
    } else {
      feedback.add('Add numbers');
    }

    // Special characters (0-15 points)
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(widget.password)) {
      score += 15;
    } else {
      feedback.add('Add special characters');
    }

    // Bonus for variety
    final hasUpperAndLower = RegExp(r'[A-Z]').hasMatch(widget.password) &&
        RegExp(r'[a-z]').hasMatch(widget.password);
    final hasLettersAndNumbers = RegExp(r'[A-Za-z]').hasMatch(widget.password) &&
        RegExp(r'[0-9]').hasMatch(widget.password);
    final hasSpecialChars =
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(widget.password);

    if (hasUpperAndLower && hasLettersAndNumbers && hasSpecialChars) {
      score += 10;
    }

    // Penalties
    if (RegExp(r'^[0-9]+$').hasMatch(widget.password)) {
      score -= 20;
      feedback.add('Avoid using only numbers');
    }
    if (RegExp(r'^[a-zA-Z]+$').hasMatch(widget.password)) {
      score -= 10;
      feedback.add('Mix letters with numbers');
    }
    if (RegExp(r'(.)\1{2,}').hasMatch(widget.password)) {
      score -= 10;
      feedback.add('Avoid repeating characters');
    }

    // Ensure score is within 0-100
    score = score.clamp(0, 100);

    // Determine level
    String level;
    if (score < 30) {
      level = 'weak';
    } else if (score < 50) {
      level = 'fair';
    } else if (score < 70) {
      level = 'good';
    } else if (score < 90) {
      level = 'strong';
    } else {
      level = 'very-strong';
    }

    // Check if valid
    final isValid = widget.password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(widget.password) &&
        RegExp(r'[a-z]').hasMatch(widget.password) &&
        RegExp(r'[0-9]').hasMatch(widget.password) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(widget.password);

    setState(() {
      _score = score;
      _level = level;
      _feedback = feedback.isEmpty ? ['Password meets requirements'] : feedback;
      _isValid = isValid;
    });

    _updateAnimation(score / 100);
    widget.onStrengthChanged?.call(isValid);
  }

  void _updateAnimation(double target) {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(from: 0.0);
  }

  Color _getStrengthColor() {
    switch (_level) {
      case 'weak':
        return const Color(0xFFEF4444); // red
      case 'fair':
        return const Color(0xFFF97316); // orange
      case 'good':
        return const Color(0xFFEAB308); // yellow
      case 'strong':
        return const Color(0xFF22C55E); // green
      case 'very-strong':
        return const Color(0xFF10B981); // emerald
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  String _getLevelText() {
    switch (_level) {
      case 'weak':
        return 'Weak';
      case 'fair':
        return 'Fair';
      case 'good':
        return 'Good';
      case 'strong':
        return 'Strong';
      case 'very-strong':
        return 'Very Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        
        // Segmented Progress Bar
        Row(
          children: List.generate(4, (index) {
            // Calculate active state for this segment
            // 0: weak (score > 0)
            // 1: fair (score >= 30)
            // 2: good (score >= 70)
            // 3: strong (score >= 90)
            
            // Or simple mapping based on level:
            // weak: 1 bar
            // fair: 2 bars
            // good: 3 bars
            // strong/very-strong: 4 bars
            
            int activeBars = 0;
            switch (_level) {
              case 'weak': activeBars = 1; break;
              case 'fair': activeBars = 2; break;
              case 'good': activeBars = 3; break;
              case 'strong': 
              case 'very-strong': activeBars = 4; break;
            }
            
            final isActive = index < activeBars;
            
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0), // Gap
                decoration: BoxDecoration(
                  color: isActive ? _getStrengthColor() : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: _getStrengthColor().withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 8),
        
        // Strength Label & Score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLevelText(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStrengthColor(),
              ),
            ),
            if (_isValid)
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Great!',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Feedback Tips (Collapsible validation list)
        if (_feedback.isNotEmpty && !_isValid) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _feedback.take(3).map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                   Icon(Icons.circle, size: 4, color: Colors.white.withOpacity(0.6)),
                   const SizedBox(width: 8),
                   Text(
                     tip,
                     style: GoogleFonts.poppins(
                       fontSize: 11,
                       color: Colors.white.withOpacity(0.6),
                     ),
                   )
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}
