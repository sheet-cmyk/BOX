import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUpScreen> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(6, (_) => TextEditingController());
  bool busy = false, guardian = false;
  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || !guardian) return;
    setState(() => busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            name: fields[0].text,
            email: fields[1].text,
            phone: fields[2].text,
            password: fields[3].text,
            childName: fields[4].text,
            childAge: int.parse(fields[5].text),
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Text(
              'Your journey starts here.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < fields.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: fields[i],
                  obscureText: i == 3,
                  keyboardType: i == 1
                      ? TextInputType.emailAddress
                      : i == 2
                      ? TextInputType.phone
                      : i == 5
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: [
                      'Full Name',
                      'Email',
                      'Phone',
                      'Password',
                      "Child’s Name",
                      "Child’s Age",
                    ][i],
                  ),
                  validator: [
                    Validators.required,
                    Validators.email,
                    Validators.phone,
                    Validators.password,
                    Validators.required,
                    Validators.age,
                  ][i],
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: guardian,
              onChanged: (v) => setState(() => guardian = v ?? false),
              title: const Text(
                'I am an adult registering myself or a child in my care.',
              ),
            ),
            JbbButton(
              label: 'Create Account',
              busy: busy,
              onPressed: guardian ? submit : null,
            ),
            TextButton(
              onPressed: () => context.go('/signin'),
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    ),
  );
}
