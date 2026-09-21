import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';
class StripeService {
  Future<void> purchase(String planId, String requestId) async {
    const key = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (key.isEmpty) throw const FormatException('Stripe publishable key has not been configured.');
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings();
    final result = await FirebaseFunctions.instance.httpsCallable('createPaymentIntent').call({'planId': planId, 'requestId': requestId});
    if (result.data['status'] == 'completed') return;
    final secret = result.data['clientSecret'] as String?;
    if (secret == null) throw const FormatException('Payment is not available for this order.');
    await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(paymentIntentClientSecret: secret, merchantDisplayName: 'Junior Boy Boxing', style: ThemeMode.dark));
    await Stripe.instance.presentPaymentSheet();
  }
  String newRequestId() => const Uuid().v4();
}
