import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../payments/payments_api.dart';
import 'member_scaffold.dart';

class SubscriptionCheckoutPage extends StatefulWidget {
  final int paymentId;
  final String checkoutUrl;
  const SubscriptionCheckoutPage(
      {super.key, required this.paymentId, required this.checkoutUrl});

  @override
  State<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  bool _verifying = false;
  bool _finished = false;

  Future<void> _verify() async {
    try {
      setState(() => _verifying = true);
      final api = PaymentsApi();
      final p = await api.getPayment(widget.paymentId);
      final status = (p['status']?.toString() ?? '').toUpperCase();
      if (!mounted) return;
      if (status == 'COMPLETED') {
        _finished = true;
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment status: $status')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not verify payment: $e')));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = Uri.tryParse(widget.checkoutUrl);
    final validUrl = parsed != null && parsed.hasScheme;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          // no-op
        },
      ));
    if (validUrl) {
      controller.loadRequest(parsed);
    }

    return MemberScaffold(
      title: 'Confirm Subscription',
      currentRoute: '/member/packages',
      child: Column(
        children: [
          if (_verifying) const LinearProgressIndicator(minHeight: 2),
          Container(
            width: double.infinity,
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Complete the payment, then tap Done to verify.'),
                ),
                TextButton(
                  onPressed: _verifying ? null : _verify,
                  child: const Text('Done'),
                )
              ],
            ),
          ),
          if (validUrl)
            Expanded(child: WebViewWidget(controller: controller))
          else
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_off,
                          size: 40, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      const Text(
                        'Checkout link is unavailable right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please try again later or pick another package. If the issue persists, contact support.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
