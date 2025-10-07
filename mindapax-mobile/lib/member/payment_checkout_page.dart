import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../env.dart';
import '../payments/payments_api.dart';
import 'dart:io' show Platform;
import 'member_scaffold.dart';

class PaymentCheckoutPage extends StatefulWidget {
  const PaymentCheckoutPage({super.key});

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  final _amountCtrl = TextEditingController(text: '10000');
  final _descCtrl = TextEditingController(text: 'Mindapax payment');
  PaymentMethodMobile _method = PaymentMethodMobile.MOBILE_MONEY;
  bool _loading = false;
  String? _error;
  int? _paymentId;
  String? _checkoutUrl;
  bool _verifying = false;
  bool _finished = false;

  String _returnUrl() {
    String base = webAppBaseUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(base);
      if (u.host == 'localhost' && Platform.isAndroid) {
        base = base.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return '$base/payments/return';
  }

  Future<void> _startCheckout() async {
    final txt = _amountCtrl.text.trim();
    final amount = double.tryParse(txt);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _checkoutUrl = null;
      _paymentId = null;
    });
    try {
      final api = PaymentsApi();
      final (pid, url) = await api.createCheckout(
        amount: amount,
        method: _method,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        returnUrl: _returnUrl(),
      );
      setState(() {
        _paymentId = pid;
        _checkoutUrl = url;
      });
    } catch (e) {
      setState(() => _error = 'Failed to start checkout: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'Make a Payment',
      currentRoute: '/member/pay',
      child: SafeArea(
        child: _checkoutUrl == null || _checkoutUrl!.isEmpty
            ? _buildForm()
            : _buildWebView(),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const Text('Amount (XOF)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '10000'),
          ),
          const SizedBox(height: 16),
          const Text('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'What is this payment for?'),
          ),
          const SizedBox(height: 16),
          const Text('Method', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<PaymentMethodMobile>(
            initialValue: _method,
            items: const [
              DropdownMenuItem(value: PaymentMethodMobile.MOBILE_MONEY, child: Text('Mobile Money')), 
              DropdownMenuItem(value: PaymentMethodMobile.CARD, child: Text('Card')),
            ],
            onChanged: _loading ? null : (v) => setState(() => _method = v ?? PaymentMethodMobile.MOBILE_MONEY),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _startCheckout,
            icon: _loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payment),
            label: const Text('Pay with CinetPay'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    final url = _checkoutUrl!;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          // Detect return URL and auto-verify payment status
          final ret = _returnUrl();
          if (request.url.startsWith(ret) && !_verifying && !_finished) {
            _verifyStatus(auto: true);
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(url));

    return Column(
      children: [
        if (_verifying) const LinearProgressIndicator(minHeight: 2),
        if (_paymentId != null)
          Container(
            width: double.infinity,
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Complete the payment, then tap Done to verify (ID: $_paymentId).'),
                ),
                TextButton(
                  onPressed: _verifying ? null : _verifyStatus,
                  child: const Text('Done'),
                )
              ],
            ),
          ),
        Expanded(child: WebViewWidget(controller: controller)),
      ],
    );
  }

  Future<void> _verifyStatus({bool auto = false}) async {
    final id = _paymentId;
    if (id == null) return;
    try {
      setState(() => _verifying = true);
      final api = PaymentsApi();
      final p = await api.getPayment(id);
      final status = (p['status']?.toString() ?? '').toUpperCase();
      if (!mounted) return;
      if (!auto) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment status: $status')));
      }
      if (status == 'COMPLETED') {
        _finished = true;
        Navigator.of(context).pop(true);
      } else if (auto && (status == 'FAILED' || status == 'CANCELED')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment $status')));
      }
    } catch (e) {
      if (!mounted) return;
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not verify payment: $e')),
        );
      }
    }
    finally {
      if (mounted) setState(() => _verifying = false);
    }
  }
}
