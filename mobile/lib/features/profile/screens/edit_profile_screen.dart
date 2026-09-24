import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditState();
}

class _EditState extends ConsumerState<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(5, (_) => TextEditingController());
  bool loaded = false, busy = false;
  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.save({
        'fullName': fields[0].text.trim(),
        'phone': fields[2].text.trim(),
        'childName': fields[3].text.trim(),
        'childAge': int.parse(fields[4].text),
      });
      if (fields[1].text.trim() != FirebaseAuth.instance.currentUser?.email) {
        await repo.changeEmail(fields[1].text.trim());
        if (mounted) {
          showMessage(
            context,
            'Profile saved. Verify the new email to complete the email change.',
          );
}
      } else if (mounted) {
        showMessage(context, 'Profile saved.');
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    if (!loaded && user != null) {
      final values = [
        user['fullName'],
        user['email'],
        user['phone'],
        user['childName'],
        '${user['childAge']}',
      ];
      for (var i = 0; i < 5; i++) {
        fields[i].text = values[i] ?? '';
      }
      loaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: form,
          child: Column(
            children: [
              IconButton(
                iconSize: 60,
                tooltip: 'Change profile photo',
                icon: const Icon(Icons.add_a_photo_outlined),
                onPressed: busy
                    ? null
                    : () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          imageQuality: 85,
                        );
                        if (image == null) return;
                        try {
                          await ref
                              .read(userRepositoryProvider)
                              .uploadAvatar(File(image.path));
                          if (context.mounted) {
                            showMessage(context, 'Profile photo updated.');
}
                        } catch (e) {
                          if (context.mounted) {
                            showMessage(context, friendlyError(e));
}
                        }
                      },
              ),
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: fields[i],
                    decoration: InputDecoration(
                      labelText: [
                        'Full Name',
                        'Email',
                        'Phone',
                        "Child’s Name",
                        "Child’s Age",
                      ][i],
                    ),
                    validator: [
                      Validators.required,
                      Validators.email,
                      Validators.phone,
                      Validators.required,
                      Validators.age,
                    ][i],
                  ),
                ),
              JbbButton(
                label: 'Save Changes',
                busy: busy,
                onPressed: loaded ? save : null,
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(authRepositoryProvider)
                        .resetPassword(fields[1].text);
                    if (context.mounted) {
                      showMessage(context, 'Password reset email sent.');
}
                  } catch (e) {
                    if (context.mounted) showMessage(context, friendlyError(e));
                  }
                },
                child: const Text('Change password by email'),
              ),
              SwitchListTile(
                title: const Text('Push notifications'),
                value: user?['notificationPreferences']?['push'] ?? true,
                onChanged: (v) async {
                  try {
                    await ref.read(userRepositoryProvider).save({
                      'notificationPreferences': {
                        'push': v,
                        'email':
                            user?['notificationPreferences']?['email'] ?? true,
                      },
                    });
                  } catch (e) {
                    if (context.mounted) showMessage(context, friendlyError(e));
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Email notifications'),
                value: user?['notificationPreferences']?['email'] ?? true,
                onChanged: (v) async {
                  try {
                    await ref.read(userRepositoryProvider).save({
                      'notificationPreferences': {
                        'email': v,
                        'push':
                            user?['notificationPreferences']?['push'] ?? true,
                      },
                    });
                  } catch (e) {
                    if (context.mounted) showMessage(context, friendlyError(e));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
