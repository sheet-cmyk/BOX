import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class StripeService {
  Future<String> purchase(String planId) async {
    const configuredKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    final settings = await FirebaseFirestore.instance
        .doc('gymSettings/config')
        .get();
    final key = configuredKey.isNotEmpty
        ? configuredKey
        : settings.data()?['stripePublishableKey'] as String? ?? '';
    if (!RegExp(r'^pk_(test|live)_').hasMatch(key)) {
      throw const FormatException(
        'Card payments are not configured yet. Contact the gym for a cash or manual payment.',
      );
}
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final attemptKey = 'checkout:$uid:$planId', box = Hive.box('jbb_device');
    final requestId = box.get(attemptKey) as String? ?? const Uuid().v4();
    await box.put(attemptKey, requestId);
    dynamic data;
    try {
      data =
          (await FirebaseFunctions.instance
                  .httpsCallable('createPaymentIntent')
                  .call({'planId': planId, 'requestId': requestId}))
              .data;
    } on FirebaseFunctionsException catch (e) {
      if (e.details is Map && e.details['reason'] == 'checkout-expired') {
        await box.delete(attemptKey);
}
      rethrow;
    }
    final status = data['status'] as String;
    if (['completed', 'refunded', 'canceled'].contains(status)) {
      await box.delete(attemptKey);
      return status == 'completed'
          ? 'Payment confirmed. Your credits have been added. To buy another pack, tap Continue again.'
          : 'The previous order was $status. You can start a new purchase.';
    }
    if ([
      'succeeded',
      'processing',
      'requires_capture',
      'refund_pending',
    ].contains(status)) {
      return 'Payment is still being confirmed. Check Payments before purchasing again.';
}
    final secret = data['clientSecret'] as String?;
    if (secret == null) {
      throw const FormatException('Payment is not available for this order.');
}
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: secret,
        merchantDisplayName: 'Junior Boy Boxing',
        style: ThemeMode.dark,
      ),
    );
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return 'Payment sheet closed. Check Payments if you submitted a payment.';
}
      rethrow;
    }
    final payment = await FirebaseFirestore.instance
        .doc('payments/${data['paymentId']}')
        .get();
    if (payment.data()?['status'] == 'completed') {
      return 'Payment confirmed. Your session credits have been added.';
}
    return 'Payment submitted. Check Payments for confirmation; do not pay again while pending.';
  }
}
