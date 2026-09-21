import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
String friendlyError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Check your email and password.',
      'email-already-in-use' => 'This email already has an account. Sign in instead.',
      'network-request-failed' || 'unavailable' => 'Connection unavailable. Check your internet and retry.',
      'permission-denied' => 'You do not have access to this action.',
      _ => error.message ?? 'Unable to complete the action. Please retry.',
    };
  }
  return 'Unable to complete the action. Please retry.';
}
void showMessage(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
