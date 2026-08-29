import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';

/// Full-screen in-app Paystack checkout. Loads the Paystack [authorizationUrl]
/// in a WebView and pops `true` once payment looks complete (Paystack redirects
/// to its `/close` page, or to a `trxref` callback). The caller is expected to
/// verify the [reference] with the backend afterwards — verification is the
/// source of truth, so a missed redirect never grants or loses diamonds.
class PaystackCheckoutPage extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackCheckoutPage({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<PaystackCheckoutPage> createState() => _PaystackCheckoutPageState();
}

class _PaystackCheckoutPageState extends State<PaystackCheckoutPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.darkBg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onUrlChange: (change) => _maybeComplete(change.url),
          onNavigationRequest: (req) {
            if (_looksComplete(req.url)) {
              _complete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  /// Paystack signals a finished checkout by leaving the card form: either its
  /// hosted `/close` page (no callback configured) or a `trxref`/`reference`
  /// callback redirect.
  bool _looksComplete(String? url) {
    if (url == null) return false;
    final u = url.toLowerCase();
    final onClose = u.contains('paystack') && u.contains('/close');
    final onCallback = u.contains('trxref=') || u.contains('?reference=');
    return onClose || onCallback;
  }

  void _maybeComplete(String? url) {
    if (_looksComplete(url)) _complete();
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text('Secure checkout',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
