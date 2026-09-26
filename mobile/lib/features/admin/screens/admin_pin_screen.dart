import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';

/// Second-factor PIN gate in front of the admin dashboard. Being signed
/// in on a role:'admin' account is required just to reach this screen
/// (see the More menu); the PIN is an extra lock so the dashboard isn't
/// one tap away whenever the admin's phone is unlocked.
class AdminPinScreen extends ConsumerStatefulWidget {
  const AdminPinScreen({super.key});
  @override
  ConsumerState<AdminPinScreen> createState() => _AdminPinState();
}

class _AdminPinState extends ConsumerState<AdminPinScreen> {
  final pin = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (pin.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).verifyPin(pin.text.trim());
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Access')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the admin PIN',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text('This unlocks prices, schedule times and the store.'),
          const SizedBox(height: 28),
          TextField(
            controller: pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 8),
            maxLength: 8,
            decoration: const InputDecoration(counterText: ''),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 16),
          JbbButton(label: 'Unlock', busy: busy, onPressed: submit),
        ],
      ),
    ),
  );
}
