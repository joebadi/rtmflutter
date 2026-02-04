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
        const SizedBox(height: 8),
        
        // Progress Bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bar Container
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      // Animated Progress
                      FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getStrengthColor(),
                                _getStrengthColor().withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: _getStrengthColor().withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Strength Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password Strength: ${_getLevelText()}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStrengthColor(),
                      ),
                    ),
                    Text(
                      '$_score%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        
        // Feedback
        if (_feedback.isNotEmpty && !_isValid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getStrengthColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: _getStrengthColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Suggestions:',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._feedback.take(3).map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        
        // Success Indicator
        if (_isValid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  'Password meets all requirements',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
