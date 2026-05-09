import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

enum CheckoutProvider { stripe, paypal }

extension CheckoutProviderX on CheckoutProvider {
  String get apiName => switch (this) {
        CheckoutProvider.stripe => 'stripe',
        CheckoutProvider.paypal => 'paypal',
      };
}

/// What the backend returns when we ask it to start a checkout.
/// `url` is what we open in the system browser; `provider` and
/// `sessionId` are returned for later reconciliation.
class CheckoutSession {
  final String url;
  final String provider;
  final String? sessionId;

  CheckoutSession({required this.url, required this.provider, this.sessionId});

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      url: (json['url'] ?? json['checkoutUrl'] ?? json['approveUrl']) as String,
      provider: (json['provider'] ?? '') as String,
      sessionId: json['sessionId'] as String? ?? json['id'] as String?,
    );
  }
}

final billingApiProvider = Provider<BillingApi>((ref) {
  return BillingApi(ref.watch(apiClientProvider));
});

class BillingApi {
  final Dio _dio;
  BillingApi(this._dio);

  /// Asks the backend to create a Stripe Checkout / PayPal Order for the
  /// given plan and returns the URL we should open in the browser. The
  /// backend handles all secret keys; the Flutter client never holds them.
  Future<CheckoutSession> startCheckout({
    required String planId,
    required CheckoutProvider provider,
  }) async {
    try {
      final res = await _dio.post('/subscriptions/create-checkout', data: {
        'plan': planId,
        'provider': provider.apiName,
        'successUrl': 'pronote://checkout-success',
        'cancelUrl': 'pronote://checkout-cancel',
      });
      return CheckoutSession.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cancels the user's active subscription at the end of the current period.
  Future<void> cancel() async {
    try {
      await _dio.post('/subscriptions/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Returns a one-time URL to the Stripe / PayPal customer portal so the user
  /// can update their card, change plan, download invoices, etc.
  Future<String> portalUrl() async {
    try {
      final res = await _dio.post('/subscriptions/create-portal', data: {
        'returnUrl': 'pronote://portal-return',
      });
      final data = res.data as Map<String, dynamic>;
      return (data['url'] ?? data['portalUrl']) as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
