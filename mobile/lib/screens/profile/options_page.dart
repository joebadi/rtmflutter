import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/premium_loader.dart';
import '../../widgets/premium_message.dart';
import '../../config/theme.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  final ProfileService _profileService = ProfileService();

  bool _pushNotifications = true;
  bool _showMeOnMap = true;
  bool _goAnonymous = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrivacyState());
  }

  void _loadPrivacyState() {
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    final data = profile?['data']?['profile'] ?? profile?['data'] ?? profile;
    if (data is Map) {
      setState(() {
        _showMeOnMap = (data['showOnMap'] as bool?) ?? true;
        _goAnonymous = (data['isAnonymous'] as bool?) ?? false;
      });
    }
  }

  Future<void> _updatePrivacy({bool? showOnMap, bool? isAnonymous}) async {
    try {
      await _profileService.updatePrivacySettings(
        showOnMap: showOnMap,
        isAnonymous: isAnonymous,
      );
    } catch (_) {
      // Revert on failure
      if (!mounted) return;
      showPremiumSnack(
        context,
        'Couldn\'t save privacy setting. Please try again.',
        kind: MessageKind.error,
      );
      _loadPrivacyState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'OPTIONS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Go Premium (Embossed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/premium'),
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Go PREMIUM',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Regular Options
            _buildOptionItem(
              icon: Icons.account_balance_wallet,
              title: 'Wallet / Livestream Dashboard',
              onTap: () => context.push('/wallet'),
            ),
            _buildOptionItem(
              icon: Icons.verified,
              title: 'Apply for Verification',
              onTap: () => context.push('/verification'),
            ),
            _buildOptionItem(
              icon: Icons.language,
              title: 'App Languages',
              onTap: () => context.push('/languages'),
            ),
            _buildOptionItem(
              icon: Icons.bookmark,
              title: 'Saved Profiles',
              onTap: () => context.push('/saved-profiles'),
            ),
            _buildOptionItem(
              icon: Icons.block,
              title: 'Blocked Profiles',
              onTap: () => context.push('/blocked-profiles'),
            ),
            _buildOptionItem(
              icon: Icons.favorite,
              title: 'Liked Profiles',
              onTap: () => context.push('/liked-profiles'),
            ),
            _buildOptionItem(
              icon: Icons.visibility_off,
              title: 'Hidden Profiles',
              onTap: () => context.push('/hidden-profiles'),
            ),
            _buildOptionItem(
              icon: Icons.tune,
              title: 'Match Preference',
              onTap: () => context.push('/match-preferences'),
            ),

            const SizedBox(height: 20),

            // Privacy Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'PRIVACY SETTINGS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Appearance — Dark mode toggle
            Consumer<ThemeProvider>(
              builder: (context, theme, _) => _buildToggleItem(
                title: 'Dark Mode',
                subtitle: 'Switch between dark and light appearance',
                value: theme.mode == ThemeMode.dark,
                onChanged: (v) =>
                    theme.setMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),

            // Privacy Toggles
            _buildToggleItem(
              title: 'Push Notifications',
              subtitle: 'Keep it on, if you want to receive notifications',
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
            ),
            _buildToggleItem(
              title: 'Show Me On Map',
              subtitle: 'Keep it on, if you want to be seen on Map',
              value: _showMeOnMap,
              onChanged: (v) {
                setState(() => _showMeOnMap = v);
                _updatePrivacy(showOnMap: v);
              },
            ),
            _buildToggleItem(
              title: 'Go Anonymous',
              subtitle:
                  'Turn On, if you don\'t want to be seen anywhere in the app',
              value: _goAnonymous,
              onChanged: (v) {
                setState(() => _goAnonymous = v);
                _updatePrivacy(isAnonymous: v);
              },
            ),

            const SizedBox(height: 20),

            // Legal Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'LEGAL',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildLegalItem(
                title: 'Privacy Policy',
                onTap: () => context.push('/legal/privacy_policy')),
            _buildLegalItem(
                title: 'Terms Of Use',
                onTap: () => context.push('/legal/terms_of_use')),

            const SizedBox(height: 24),

            // Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Clear profile data first
                      Provider.of<ProfileProvider>(context, listen: false)
                          .clearProfile();
                      
                      await Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppTheme.hairline(context),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppTheme.surface(context),
                    ),
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // App Version
            Center(
              child: Column(
                children: [
                  const AppLogo(height: 26),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delete Account Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      _showDeleteAccountDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.red.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppTheme.surface(context),
                    ),
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF5722), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppTheme.textFaint(context), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFFFF5722),
                activeTrackColor: const Color(0xFFFF5722).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem({required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFF5722),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performAccountDeletion();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calls the backend to permanently delete the account, then signs the user
  /// out and returns them to the login screen.
  Future<void> _performAccountDeletion() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    // Blocking loader while the request is in flight.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: PremiumLoader()),
    );

    try {
      profile.clearProfile();
      final ok = await auth.deleteAccount();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

      if (ok) {
        await showPremiumAlert(
          context,
          title: 'Account deleted',
          message: 'Your account and data have been removed. Take care.',
          kind: MessageKind.success,
          autoDismiss: const Duration(milliseconds: 1500),
        );
        if (mounted) context.go('/login');
      } else {
        await showPremiumAlert(
          context,
          title: 'Couldn’t delete account',
          message: 'Something went wrong. Please try again.',
          kind: MessageKind.error,
          buttonText: 'Try again',
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
      await showPremiumAlert(
        context,
        title: 'Something went wrong',
        message: 'Please check your connection and try again.',
        kind: MessageKind.error,
        buttonText: 'Dismiss',
      );
    }
  }
}
