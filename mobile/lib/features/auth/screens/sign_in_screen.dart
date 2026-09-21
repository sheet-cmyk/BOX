import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/auth_provider.dart';
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override ConsumerState<SignInScreen> createState() => _SignInState();
}
class _SignInState extends ConsumerState<SignInScreen> {
  final form = GlobalKey<FormState>(), email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try { await action(); if (mounted) context.go('/home'); }
    catch (e) { if (mounted) showMessage(context, friendlyError(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Sign In')), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: form, autovalidateMode: AutovalidateMode.onUserInteraction, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Back in your corner.', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 10), const Text('Sign in to book your next session.'), const SizedBox(height: 32), TextFormField(controller: email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email'), validator: Validators.email), const SizedBox(height: 16), TextFormField(controller: password, obscureText: true, autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Password'), validator: Validators.required), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : () async { if (Validators.email(email.text) != null) { showMessage(context, 'Enter your email first.'); return; } try { await ref.read(authRepositoryProvider).resetPassword(email.text); if (context.mounted) showMessage(context, 'Password reset email sent.'); } catch (e) { if (context.mounted) showMessage(context, friendlyError(e)); } }, child: const Text('Forgot Password?'))), JbbButton(label: 'Sign In', busy: busy, onPressed: () { if (form.currentState!.validate()) run(() => ref.read(authRepositoryProvider).signIn(email.text, password.text)); }), const SizedBox(height: 16), OutlinedButton(onPressed: busy ? null : () => run(() => ref.read(authRepositoryProvider).googleSignIn()), child: const Text('Continue with Google')), TextButton(onPressed: () => context.push('/phone'), child: const Text('Sign in with phone')), TextButton(onPressed: () => context.go('/signup'), child: const Text('New here? Get Started'))]))));
}
