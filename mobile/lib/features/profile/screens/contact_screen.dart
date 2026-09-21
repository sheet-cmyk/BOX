import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../providers/profile_provider.dart';
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? {};
    Future<void> open(Uri uri) async { try { if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) showMessage(context, 'Could not open this link.'); } catch (e) { if (context.mounted) showMessage(context, friendlyError(e)); } }
    return Scaffold(appBar: AppBar(title: const Text('Contact Us')), body: ListView(padding: const EdgeInsets.all(24), children: [Text(settings['coachName'] ?? 'Coach Sharif', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 16), Text(settings['address'] ?? AppStrings.address), const SizedBox(height: 24), if ((settings['phone'] ?? '').isNotEmpty) ListTile(leading: const Icon(Icons.phone, color: Colors.red), title: Text(settings['phone']), onTap: () => open(Uri(scheme: 'tel', path: settings['phone']))), if ((settings['email'] ?? '').isNotEmpty) ListTile(leading: const Icon(Icons.mail, color: Colors.red), title: Text(settings['email']), onTap: () => open(Uri(scheme: 'mailto', path: settings['email']))), FilledButton(onPressed: () => open(Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': settings['address'] ?? AppStrings.address})), child: const Text('Get Directions')), const SizedBox(height: 24), Text('Operating Hours', style: Theme.of(context).textTheme.titleLarge), for (final entry in (settings['operatingHours'] as Map? ?? {}).entries) ListTile(title: Text(entry.key.toString()), trailing: Text(entry.value.toString())), if ((settings['operatingHours'] as Map? ?? {}).isEmpty) const Text('Contact the gym to confirm training hours.')]));
  }
}
