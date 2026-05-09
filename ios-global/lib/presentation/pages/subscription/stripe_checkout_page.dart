/// Stripe Checkout Page — SEASONS Global
/// Integrates with backend /api/v1/stripe/checkout
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class StripeCheckoutPage extends StatefulWidget {
  final String plan;
  const StripeCheckoutPage({super.key, this.plan = 'premium'});

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  bool _loading = true;
  String? _checkoutUrl;
  String? _error;

  static const _baseUrl = 'http://116.62.32.43:4000';

  @override
  void initState() {
    super.initState();
    _createCheckoutSession();
  }

  Future<void> _createCheckoutSession() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      final resp = await dio.post('/api/v1/stripe/checkout', data: {
        'plan': widget.plan,
        'user_id': 'user-001',
        'success_url': 'shunshi://stripe/success',
        'cancel_url': 'shunshi://stripe/cancel',
      });
      if (resp.data is Map && resp.data['url'] != null) {
        setState(() {
          _checkoutUrl = resp.data['url'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to create checkout session';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Payment service unavailable. Please try again later.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: ShunShiColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Checkout',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: ShunShiColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: ShunShiColors.textTertiary),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(color: ShunShiColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createCheckoutSession,
              style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Complete Your Subscription',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 24, fontWeight: FontWeight.w300)),
        const SizedBox(height: 8),
        Text('You will be redirected to Stripe to complete payment securely.',
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ShunShiColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock, color: ShunShiColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Powered by Stripe',
                      style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // In production, open the Stripe checkout URL in a WebView or browser
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening Stripe checkout: $_checkoutUrl')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ShunShiColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
