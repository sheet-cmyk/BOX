import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override
  State<PhoneScreen> createState() => _PhoneState();
}

class _PhoneState extends State<PhoneScreen> {
  final phone = TextEditingController(), code = TextEditingController();
  String? verificationId;
  bool busy = false;
  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> finish(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      await AuthRepository().initializeProfile();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (verificationId != null) {
      setState(() => busy = true);
      await finish(
        PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: code.text,
        ),
      );
      return;
    }
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone.text.trim())) {
      showMessage(
        context,
        'Use international format, for example +12095550123.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.text.trim(),
        verificationCompleted: finish,
        verificationFailed: (error) {
          if (mounted) {
            setState(() => busy = false);
            showMessage(context, friendlyError(error));
          }
        },
        codeSent: (id, token) {
          if (mounted) {
            setState(() {
              verificationId = id;
              busy = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (id) {
          if (mounted) {
            setState(() {
              verificationId = id;
              busy = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        showMessage(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Phone Sign In')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: phone,
            enabled: verificationId == null,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone with country code',
            ),
          ),
          const SizedBox(height: 16),
          if (verificationId != null)
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SMS verification code',
              ),
            ),
          const SizedBox(height: 20),
          JbbButton(
            label: verificationId == null ? 'Send Code' : 'Verify Code',
            busy: busy,
            onPressed: submit,
          ),
          const SizedBox(height: 16),
          const Text(
            'SMS rates may apply. Your number is used for account authentication.',
          ),
        ],
      ),
    ),
  );
}
