import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/relationship_service.dart';
import '../../widgets/premium_loader.dart';

/// Reusable list of profiles (Saved / Hidden / Blocked) with a per-item action.
class RelationshipListScreen extends StatefulWidget {
  const RelationshipListScreen({
    super.key,
    required this.title,
    required this.fetch,
    required this.actionLabel,
    required this.action,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final Future<List<dynamic>> Function() fetch;
  final String actionLabel;
  final Future<void> Function(String userId) action;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  State<RelationshipListScreen> createState() => _RelationshipListScreenState();
}

class _RelationshipListScreenState extends State<RelationshipListScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  final Set<String> _busy = {};

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
      final list = await widget.fetch();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load ${widget.title.toLowerCase()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(String userId) async {
    setState(() => _busy.add(userId));
    try {
      await widget.action(userId);
      if (!mounted) return;
      setState(() => _items.removeWhere((u) => (u['id']?.toString()) == userId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(userId));
    }
  }

  String _photo(Map u) {
    final profile = u['profile'] as Map?;
    final photos = profile?['photos'] as List?;
    if (photos == null || photos.isEmpty) return '';
    final url = (photos[0]['url'] ?? '').toString();
    if (url.isEmpty) return '';
    return url.startsWith('http') ? url : '${ApiConfig.socketUrl}$url';
  }

  int _age(Map? p) {
    if (p == null) return 0;
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
        title: Text(widget.title,
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
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _row(_items[i]),
                      ),
                    ),
    );
  }

  Widget _row(dynamic u) {
    if (u is! Map) return const SizedBox.shrink();
    final profile = u['profile'] as Map?;
    final id = (u['id'] ?? '').toString();
    final name = (profile?['firstName'] ?? 'Someone').toString();
    final age = _age(profile);
    final photo = _photo(u);
    final online = u['isOnline'] == true;
    final busy = _busy.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (profile != null) {
                final data = Map<String, dynamic>.from(profile);
                data['user'] = {'id': id, 'isOnline': online};
                data['userId'] = id;
                context.push('/user-profile', extra: data);
              }
            },
            child: Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: photo.isNotEmpty
                        ? Image.network(photo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback())
                        : _avatarFallback(),
                  ),
                ),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppTheme.surface(context), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              age > 0 ? '$name, $age' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context)),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: busy ? null : () => _runAction(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: PremiumLoader(strokeWidth: 2, color: AppTheme.accent),
                    )
                  : Text(widget.actionLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppTheme.surface2(context),
        child: Icon(Icons.person_rounded,
            size: 28, color: AppTheme.textFaint(context)),
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
              child: Icon(widget.emptyIcon,
                  size: 46, color: AppTheme.accent.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 18),
            Text(widget.emptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(widget.emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                    height: 1.45)),
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

// ---- Thin wrappers -------------------------------------------------------

class SavedProfilesScreen extends StatelessWidget {
  const SavedProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = RelationshipService();
    return RelationshipListScreen(
      title: 'Saved Profiles',
      fetch: s.getSaved,
      actionLabel: 'Remove',
      action: s.unsave,
      emptyIcon: Icons.bookmark_border_rounded,
      emptyTitle: 'No saved profiles',
      emptySubtitle: 'Profiles you save will appear here.',
    );
  }
}

class BlockedProfilesScreen extends StatelessWidget {
  const BlockedProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = RelationshipService();
    return RelationshipListScreen(
      title: 'Blocked Profiles',
      fetch: s.getBlocked,
      actionLabel: 'Unblock',
      action: s.unblock,
      emptyIcon: Icons.block_rounded,
      emptyTitle: 'No blocked profiles',
      emptySubtitle: 'People you block won\'t be able to message you.',
    );
  }
}

class HiddenProfilesScreen extends StatelessWidget {
  const HiddenProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = RelationshipService();
    return RelationshipListScreen(
      title: 'Hidden Profiles',
      fetch: s.getHidden,
      actionLabel: 'Unhide',
      action: s.unhide,
      emptyIcon: Icons.visibility_off_rounded,
      emptyTitle: 'No hidden profiles',
      emptySubtitle: 'Profiles you hide are removed from your feed. Unhide them here anytime.',
    );
  }
}
