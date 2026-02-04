import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/password_strength_indicator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String _selectedCountryCode = 'NG+234'; // Default to Nigeria

  // Country codes list with flags
  final List<Map<String, String>> _countryCodes = [
    {'code': 'NG+234', 'dialCode': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': 'US+1', 'dialCode': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': 'GB+44', 'dialCode': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': 'GH+233', 'dialCode': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': 'KE+254', 'dialCode': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {
      'code': 'ZA+27',
      'dialCode': '+27',
      'flag': '🇿🇦',
      'name': 'South Africa',
    },
    {'code': 'CA+1', 'dialCode': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms of Service and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the dial code from selected country
    final selectedCountry = _countryCodes.firstWhere(
      (country) => country['code'] == _selectedCountryCode,
    );
    final dialCode = selectedCountry['dialCode']!;

    // Combine dial code with phone number
    // Strip leading zero if present to ensure correct international format
    String phoneInput = _phoneCtrl.text.trim();
    if (phoneInput.startsWith('0')) {
      phoneInput = phoneInput.substring(1);
    }
    final fullPhoneNumber = '$dialCode$phoneInput';

    // Call backend API to register user
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      fullPhoneNumber,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to OTP verification page with phone number
      context.push(
        '/otp-verification',
        extra: {
          'phoneNumber': fullPhoneNumber,
          'email': _emailCtrl.text.trim(),
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
        },
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
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
                  ),
                ),

                // Glassmorphic Form Card
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title
                                  Text(
                                    'Sign up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Let's create your account",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // First Name
                                  _buildTextField(
                                    controller: _firstNameCtrl,
                                    label: 'First Name',
                                    hint: 'John',
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),

                                  const SizedBox(height: 14),

                                  // Last Name
                                  _buildTextField(
                                    controller: _lastNameCtrl,
                                    label: 'Last Name',
                                    hint: 'Doe',
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),

                                  const SizedBox(height: 14),

                                  // Phone Number with Country Code
                                  _buildPhoneField(),

                                  const SizedBox(height: 14),

                                  // Email
                                  _buildTextField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    hint: 'john@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                  ),

                                  const SizedBox(height: 14),

                                  // Password
                                  _buildPasswordField(
                                    controller: _passCtrl,
                                    label: 'Password',
                                    obscureText: _obscurePassword,
                                    onToggle: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),

                                  // Password Strength Indicator
                                  PasswordStrengthIndicator(
                                    password: _passCtrl.text,
                                  ),

                                  const SizedBox(height: 14),

                                  // Confirm Password
                                  _buildPasswordField(
                                    controller: _confirmPassCtrl,
                                    label: 'Confirm Password',
                                    obscureText: _obscureConfirmPassword,
                                    onToggle: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Terms and Conditions
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _agreedToTerms,
                                          onChanged: (value) => setState(
                                            () =>
                                                _agreedToTerms = value ?? false,
                                          ),
                                          activeColor: const Color(0xFFFF6B35),
                                          side: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'I agree to ',
                                              ),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: GoogleFonts.poppins(
                                                  color: const Color(
                                                    0xFFFF6B35,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: GoogleFonts.poppins(
                                                  color: const Color(
                                                    0xFFFF6B35,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF6B35,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFFFF6B35,
                                        ).withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'Continue',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Sign In Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.pop(),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Log in',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFFFF6B35),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.95),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
          validator: (value) =>
              value == null || value.length < 6 ? 'Min 6 characters' : null,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.95),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Country Code Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    isDense: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _countryCodes.map((country) {
                      return DropdownMenuItem<String>(
                        value: country['code'],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country['flag']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              country['dialCode']!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountryCode = value!;
                      });
                    },
                  ),
                ),
              ),

              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: '800 000 0000',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
