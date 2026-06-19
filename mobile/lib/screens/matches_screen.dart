import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../services/like_service.dart';
import '../services/match_service.dart';
import '../widgets/notification_icon.dart';
import '../widgets/premium_loader.dart';
import '../widgets/app_logo.dart';

/// Matches — replaces the old Likes page. Two tabs:
///  • Mutual: people you and they have both liked.
///  • Preferred: profiles that meet 100% of your match preferences, with
///    sorting and quick filters.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

enum _PrefSort { compatibility, ageAsc, ageDesc, recentlyActive }
enum _PrefFilter { all, online, verified }

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final LikeService _likeService = LikeService();
  final MatchService _matchService = MatchService();

  bool _loadingMutual = true;
  bool _loadingPreferred = true;
  String? _errorMutual;
  String? _errorPreferred;
  List<dynamic> _mutual = [];
  List<dynamic> _preferred = []; // suggestion items with compatibility==100

  _PrefSort _sort = _PrefSort.compatibility;
  _PrefFilter _filter = _PrefFilter.all;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadMutual();
    _loadPreferred();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------- data

  Future<void> _loadMutual() async {
    setState(() {
      _loadingMutual = true;
      _errorMutual = null;
    });
    try {
      final list = await _likeService.getMutualLikes();
      if (!mounted) return;
      setState(() => _mutual = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMutual = 'Could not load your matches');
    } finally {
      if (mounted) setState(() => _loadingMutual = false);
    }
  }

  Future<void> _loadPreferred() async {
    setState(() {
      _loadingPreferred = true;
      _errorPreferred = null;
    });
    try {
      final list = await _matchService.getMatchSuggestions(limit: 50);
      // Preferred = profiles that satisfy ALL set preferences (100%).
      final perfect = list.where((item) {
        final c = item is Map ? item['compatibility'] : null;
        final score = (c is Map && c['score'] is num)
            ? (c['score'] as num).round()
            : null;
        return score == 100;
      }).toList();
      if (!mounted) return;
      setState(() => _preferred = perfect);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorPreferred = 'Could not load preferred matches');
    } finally {
      if (mounted) setState(() => _loadingPreferred = false);
    }
  }

  // -------------------------------------------------------------- helpers

  /// Normalize either a mutual-like item or a suggestion item into the profile
  /// map UserProfilePage / cards expect.
  Map<String, dynamic> _profileOf(dynamic item) {
    if (item is! Map) return {};
    if (item['likedUser'] != null) {
      // Mutual like: profile lives under likedUser.profile.
      final liked = item['likedUser'] as Map? ?? {};
      final profile = Map<String, dynamic>.from(liked['profile'] as Map? ?? {});
      profile['user'] ??= {
        'id': liked['id'],
        'isOnline': liked['isOnline'],
        'isPremium': liked['isPremium'],
        'lastActive': liked['lastActive'],
      };
      profile['userId'] ??= liked['id'];
      return profile;
    }
    if (item['profile'] != null) {
      return Map<String, dynamic>.from(item['profile'] as Map);
    }
    return Map<String, dynamic>.from(item);
  }

  String _photoUrl(Map profile) {
    final photos = profile['photos'] as List?;
    if (photos == null || photos.isEmpty) return '';
    final primary = photos.firstWhere(
      (p) => p['isPrimary'] == true,
      orElse: () => photos.first,
    );
    final url = (primary['url'] ?? '').toString();
    if (url.isEmpty) return '';
    return url.startsWith('http') ? url : '${ApiConfig.socketUrl}$url';
  }

  int _ageOf(Map profile) {
    if (profile['age'] is num) return (profile['age'] as num).round();
    final dob = profile['dateOfBirth'];
    if (dob != null) {
      try {
        final d = DateTime.parse(dob.toString());
        return DateTime.now().year - d.year;
      } catch (_) {}
    }
    return 0;
  }

  String _nameOf(Map profile) => (profile['firstName'] ?? 'Someone').toString();

  bool _isOnline(Map profile) =>
      (profile['user']?['isOnline'] ?? profile['isOnline']) == true;

  void _openProfile(dynamic item) {
    context.push('/user-profile', extra: _profileOf(item));
  }

  void _message(dynamic item) {
    final profile = _profileOf(item);
    final userId = profile['user']?['id'] ?? profile['userId'];
    if (userId == null) return;
    context.push('/chat/$userId', extra: {
      'receiverId': userId,
      'receiverName': _nameOf(profile),
      'receiverPhoto': _photoUrl(profile),
    });
  }

  // Apply sort + filter to the preferred list.
  List<dynamic> get _preferredView {
    final items = _preferred.where((item) {
      final p = _profileOf(item);
      switch (_filter) {
        case _PrefFilter.online:
          return _isOnline(p);
        case _PrefFilter.verified:
          return (p['user']?['isPremium'] ?? p['isVerified']) == true;
        case _PrefFilter.all:
          return true;
      }
    }).toList();

    int recentRank(dynamic item) {
      final p = _profileOf(item);
      final la = p['user']?['lastActive'] ?? p['lastActive'];
      if (la == null) return 0;
      return DateTime.tryParse(la.toString())?.millisecondsSinceEpoch ?? 0;
    }

    switch (_sort) {
      case _PrefSort.ageAsc:
        items.sort((a, b) => _ageOf(_profileOf(a)).compareTo(_ageOf(_profileOf(b))));
        break;
      case _PrefSort.ageDesc:
        items.sort((a, b) => _ageOf(_profileOf(b)).compareTo(_ageOf(_profileOf(a))));
        break;
      case _PrefSort.recentlyActive:
        items.sort((a, b) => recentRank(b).compareTo(recentRank(a)));
        break;
      case _PrefSort.compatibility:
        break; // already ordered by the backend
    }
    return items;
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _tabs(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _mutualTab(),
                  _preferredTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(height: 20),
                const SizedBox(height: 8),
                Text('Matches',
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context))),
                const SizedBox(height: 2),
                Text('Your connections & perfect-fit profiles',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          NotificationIcon(isDark: !AppTheme.isLight(context)),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary(context),
        labelStyle:
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Mutual'),
          Tab(text: 'Preferred'),
        ],
      ),
    );
  }

  // ----- Mutual tab ------------------------------------------------------

  Widget _mutualTab() {
    if (_loadingMutual) return const Center(child: PremiumLoader());
    if (_errorMutual != null) {
      return _errorState(_errorMutual!, _loadMutual);
    }
    if (_mutual.isEmpty) {
      return _emptyState(
        Icons.favorite_rounded,
        'No mutual matches yet',
        'When you and someone like each other, they\'ll appear here.',
      );
    }
    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface(context),
      onRefresh: _loadMutual,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _mutual.length,
        itemBuilder: (_, i) => _matchCard(_mutual[i], mutual: true),
      ),
    );
  }

  // ----- Preferred tab ---------------------------------------------------

  Widget _preferredTab() {
    if (_loadingPreferred) return const Center(child: PremiumLoader());
    if (_errorPreferred != null) {
      return _errorState(_errorPreferred!, _loadPreferred);
    }
    final view = _preferredView;
    return Column(
      children: [
        _preferredControls(),
        Expanded(
          child: _preferred.isEmpty
              ? _emptyState(
                  Icons.auto_awesome_rounded,
                  'No perfect matches yet',
                  'Profiles that match 100% of your preferences show here. Keep your preferences sharp and check back.',
                )
              : view.isEmpty
                  ? _emptyState(Icons.filter_alt_off_rounded, 'Nothing matches that filter',
                      'Try a different filter.')
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.surface(context),
                      onRefresh: _loadPreferred,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: view.length,
                        itemBuilder: (_, i) =>
                            _matchCard(view[i], mutual: false),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _preferredControls() {
    String sortLabel(_PrefSort s) {
      switch (s) {
        case _PrefSort.compatibility:
          return 'Best match';
        case _PrefSort.ageAsc:
          return 'Age ↑';
        case _PrefSort.ageDesc:
          return 'Age ↓';
        case _PrefSort.recentlyActive:
          return 'Recently active';
      }
    }

    Widget filterChip(_PrefFilter f, String label) {
      final on = _filter == f;
      return GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: on ? AppTheme.accentGradient : null,
            color: on ? null : AppTheme.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: on ? Colors.transparent : AppTheme.hairline(context)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  color: on ? Colors.white : AppTheme.textSecondary(context))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  filterChip(_PrefFilter.all, 'All'),
                  filterChip(_PrefFilter.online, 'Online'),
                  filterChip(_PrefFilter.verified, 'Premium'),
                ],
              ),
            ),
          ),
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.hairline(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort_rounded, color: AppTheme.accent, size: 16),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<_PrefSort>(
                    value: _sort,
                    isDense: true,
                    dropdownColor: AppTheme.surface(context),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary(context), size: 18),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    items: _PrefSort.values
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(sortLabel(s))))
                        .toList(),
                    onChanged: (s) => setState(() => _sort = s ?? _sort),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- Match card ------------------------------------------------------

  Widget _matchCard(dynamic item, {required bool mutual}) {
    final profile = _profileOf(item);
    final name = _nameOf(profile);
    final age = _ageOf(profile);
    final photo = _photoUrl(profile);
    final online = _isOnline(profile);
    final score = (item is Map && item['compatibility'] is Map)
        ? (item['compatibility']['score'] as num?)?.round()
        : null;

    return GestureDetector(
      onTap: () => _openProfile(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo / fallback
            if (photo.isNotEmpty)
              Image.network(photo, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoFallback())
            else
              _photoFallback(),
            // Bottom gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            // Top badges
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  if (mutual)
                    _badge(const Color(0xFFE91E63), Icons.favorite_rounded,
                        'Match')
                  else if (score != null)
                    _badge(const Color(0xFFFFA500), Icons.auto_awesome_rounded,
                        '$score%'),
                  const Spacer(),
                  if (online)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom info
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    age > 0 ? '$name, $age' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _cardButton(
                          mutual ? 'Message' : 'Say hi',
                          mutual
                              ? Icons.chat_bubble_rounded
                              : Icons.waving_hand_rounded,
                          () => _message(item),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _badge(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent.withOpacity(0.25),
            AppTheme.surface2(context),
          ],
        ),
      ),
      child: Icon(Icons.person_rounded,
          size: 56, color: AppTheme.fg(context, 0.5)),
    );
  }

  // ----- States ----------------------------------------------------------

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: 46, color: AppTheme.accent.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 18),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 8),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppTheme.fg(context, 0.5),
                          height: 1.45)),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Explore people',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message, Future<void> Function() retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 44, color: AppTheme.fg(context, 0.4)),
          const SizedBox(height: 14),
          Text(message,
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary(context), fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
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
