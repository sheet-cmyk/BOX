import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/profile_provider.dart';

final waiverProvider = StreamProvider(
  (ref) => FirebaseFirestore.instance.doc('legalDocuments/waiver').snapshots(),
);

class WaiverScreen extends ConsumerStatefulWidget {
  const WaiverScreen({super.key});
  @override
  ConsumerState<WaiverScreen> createState() => _WaiverState();
}

class _WaiverState extends ConsumerState<WaiverScreen> {
  final name = TextEditingController();
  bool adult = false, agree = false, guardian = false, busy = false;
  String? version;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> sign(Map<String, dynamic> waiver) async {
    if (!adult || !agree || name.text.trim().length < 2) {
      showMessage(context, 'Enter your name and confirm both agreements.');
      return;
    }
    setState(() => busy = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('acceptWaiver').call({
        'version': waiver['version'],
        'signerName': name.text.trim(),
        'capacity': guardian ? 'guardian' : 'participant',
        'adult': adult,
        'agree': agree,
      });
      if (mounted) showMessage(context, 'Your agreement has been recorded.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Waiver & Disclaimer')),
      body: ref
          .watch(waiverProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text(friendlyError(e))),
            data: (snapshot) {
              final waiver = snapshot.data();
              if (version != waiver?['version']) {
                version = waiver?['version'];
                adult = false;
                agree = false;
              }
              final published = waiver?['published'] == true;
              final accepted =
                  published &&
                  profile?['waiverVersion'] == waiver?['version'] &&
                  profile?['waiverParticipantName'] ==
                      profile?['childName']?.trim() &&
                  profile?['waiverParticipantAge'] == profile?['childAge'];
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (!published)
                    const Text(
                      'DRAFT · Signing opens after the gym approves and publishes its final wording.',
                      style: TextStyle(color: Colors.amber),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    published ? waiver!['body'] : AppStrings.waiver,
                    style: const TextStyle(height: 1.7),
                  ),
                  const SizedBox(height: 24),
                  if (accepted)
                    const Text('Your agreement to this version is recorded.')
                  else if (published &&
                      FirebaseAuth.instance.currentUser?.isAnonymous ==
                          false) ...[
                    Text(
                      'Participant: ${profile?['childName'] ?? ''} · Age: ${profile?['childAge'] ?? ''}',
                    ),
                    TextButton(
                      onPressed: () => context.push('/profile'),
                      child: const Text('Edit participant details'),
                    ),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Your full legal name',
                      ),
                      maxLength: 100,
                    ),
                    CheckboxListTile(
                      value: guardian,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => guardian = v ?? false),
                      title: const Text(
                        'I am the parent or legal guardian (required for a participant under 18).',
                      ),
                    ),
                    CheckboxListTile(
                      value: adult,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => adult = v ?? false),
                      title: const Text(
                        'I am 18 or older and authorized to sign for this participant.',
                      ),
                    ),
                    CheckboxListTile(
                      value: agree,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => agree = v ?? false),
                      title: const Text(
                        'I read, understand and agree to this version, and submit my name as my electronic signature.',
                      ),
                    ),
                    JbbButton(
                      label: 'Record My Agreement',
                      busy: busy,
                      onPressed: () => sign(waiver!),
                    ),
                  ] else if (published)
                    const Text(
                      'Sign in with a registered account to sign this agreement.',
                    ),
                ],
              );
            },
          ),
    );
  }
}
