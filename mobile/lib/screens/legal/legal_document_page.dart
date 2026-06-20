import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/legal_service.dart';
import '../../widgets/premium_loader.dart';

/// Renders a legal document (Privacy Policy / Terms of Use) fetched from the
/// backend. Content is editable from the admin panel. Theme-aware.
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({
    super.key,
    required this.slug,
    required this.fallbackTitle,
  });

  final String slug;
  final String fallbackTitle;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  final LegalService _service = LegalService();

  bool _loading = true;
  bool _error = false;
  Map<String, dynamic>? _doc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final doc = await _service.fetch(widget.slug);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _error = doc == null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  String? get _updated {
    final raw = _doc?['updatedAt'];
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = dt.toLocal();
    return 'Last updated ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = (_doc?['title'] as String?) ?? widget.fallbackTitle;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
      ),
      body: _loading
          ? const Center(child: PremiumLoader())
          : _error
              ? _errorState()
              : _content(title),
    );
  }

  Widget _content(String title) {
    final body = (_doc?['content'] as String?)?.trim() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context))),
          if (_updated != null) ...[
            const SizedBox(height: 4),
            Text(_updated!,
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: AppTheme.textFaint(context))),
          ],
          const SizedBox(height: 16),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.6,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 40, color: AppTheme.textFaint(context)),
            const SizedBox(height: 14),
            Text('Couldn’t load this document',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context))),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(14)),
                child: Text('Retry',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
