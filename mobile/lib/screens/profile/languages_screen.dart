import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/theme.dart';

/// App language selector. Persists the choice; full localization wiring can
/// follow, but the preference is captured here.
class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  static const _key = 'app_language';
  final _storage = const FlutterSecureStorage();

  // (code, English name, native name, flag)
  static const List<List<String>> _languages = [
    ['en', 'English', 'English', '🇬🇧'],
    ['fr', 'French', 'Français', '🇫🇷'],
    ['ar', 'Arabic', 'العربية', '🇸🇦'],
    ['ha', 'Hausa', 'Hausa', '🇳🇬'],
    ['ig', 'Igbo', 'Igbo', '🇳🇬'],
    ['yo', 'Yoruba', 'Yorùbá', '🇳🇬'],
    ['pcm', 'Pidgin', 'Naijá', '🇳🇬'],
    ['sw', 'Swahili', 'Kiswahili', '🇰🇪'],
    ['pt', 'Portuguese', 'Português', '🇵🇹'],
    ['es', 'Spanish', 'Español', '🇪🇸'],
  ];

  String _selected = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null && mounted) setState(() => _selected = saved);
  }

  Future<void> _select(String code) async {
    setState(() => _selected = code);
    await _storage.write(key: _key, value: code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language preference saved',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary(context)),
        title: Text('App Languages',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _languages.length,
        itemBuilder: (_, i) {
          final l = _languages[i];
          final on = _selected == l[0];
          return GestureDetector(
            onTap: () => _select(l[0]),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: on
                    ? AppTheme.accent.withValues(alpha: 0.12)
                    : AppTheme.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: on ? AppTheme.accent : AppTheme.hairline(context)),
              ),
              child: Row(
                children: [
                  Text(l[3], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l[1],
                            style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(context))),
                        Text(l[2],
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context))),
                      ],
                    ),
                  ),
                  if (on)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.accent, size: 22)
                  else
                    Icon(Icons.circle_outlined,
                        color: AppTheme.textFaint(context), size: 22),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
