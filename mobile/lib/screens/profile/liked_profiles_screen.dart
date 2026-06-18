import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/like_service.dart';
import '../../widgets/premium_loader.dart';

/// Profiles the user has liked (sent likes).
class LikedProfilesScreen extends StatefulWidget {
  const LikedProfilesScreen({super.key});

  @override
  State<LikedProfilesScreen> createState() => _LikedProfilesScreenState();
}

class _LikedProfilesScreenState extends State<LikedProfilesScreen> {
  final LikeService _likeService = LikeService();
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _likeService.getSentLikes();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load liked profiles');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _profileOf(dynamic item) {
    if (item is! Map) return {};
    final liked = item['likedUser'] as Map? ?? {};
    final profile = Map<String, dynamic>.from(liked['profile'] as Map? ?? {});
    profile['user'] ??= {
      'id': liked['id'],
      'isOnline': liked['isOnline'],
    };
    profile['userId'] ??= liked['id'];
    return profile;
  }

  String _photo(Map p) {
    final photos = p['photos'] as List?;
    if (photos == null || photos.isEmpty) return '';
    final url = (photos[0]['url'] ?? '').toString();
    if (url.isEmpty) return '';
    return url.startsWith('http') ? url : '${ApiConfig.socketUrl}$url';
  }

  int _age(Map p) {
    if (p['age'] is num) return (p['age'] as num).round();
    final dob = p['dateOfBirth'];
    if (dob != null) {
      try {
        return DateTime.now().year - DateTime.parse(dob.toString()).year;
      } catch (_) {}
    }
    return 0;
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
        title: Text('Liked Profiles',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
      ),
      body: _loading
          ? const Center(child: PremiumLoader())
          : _error != null
              ? _errorState()
              : _items.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _card(_items[i]),
                      ),
                    ),
    );
  }

  Widget _card(dynamic item) {
    final p = _profileOf(item);
    final name = (p['firstName'] ?? 'Someone').toString();
    final age = _age(p);
    final photo = _photo(p);
    return GestureDetector(
      onTap: () => context.push('/user-profile', extra: p),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo.isNotEmpty)
              Image.network(photo, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback())
            else
              _fallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                age > 0 ? '$name, $age' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const Positioned(
              top: 10,
              right: 10,
              child: Icon(Icons.favorite_rounded,
                  color: Color(0xFFE91E63), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppTheme.surface2(context),
        child: Icon(Icons.person_rounded,
            size: 54, color: AppTheme.textFaint(context)),
      );

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.favorite_border_rounded,
                  size: 46, color: AppTheme.accent.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 18),
            Text('No liked profiles yet',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text('Profiles you like will show up here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 44, color: AppTheme.textFaint(context)),
          const SizedBox(height: 14),
          Text(_error ?? 'Something went wrong',
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary(context), fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
              ),
              child: Text('Retry',
                  style: GoogleFonts.poppins(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
