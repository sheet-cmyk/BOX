import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileState();
}
class _CompleteProfileState extends ConsumerState<CompleteProfileScreen> {
  final form = GlobalKey<FormState>(), phone = TextEditingController(), childName = TextEditingController(), childAge = TextEditingController();
  bool busy = false;
  @override void dispose() { phone.dispose(); childName.dispose(); childAge.dispose(); super.dispose(); }
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref.read(userRepositoryProvider).save({'phone': phone.text.trim(), 'childName': childName.text.trim(), 'childAge': int.parse(childAge.text)});
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) showMessage(context, friendlyError(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    if (user != null) {
      if (phone.text.isEmpty) phone.text = user['phone'] ?? '';
      if (childName.text.isEmpty) childName.text = user['childName'] ?? '';
      if (childAge.text.isEmpty && (user['childAge'] ?? 0) > 0) childAge.text = '${user['childAge']}';
    }
    return Scaffold(appBar: AppBar(title: const Text('Complete Your Profile')), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: form, autovalidateMode: AutovalidateMode.onUserInteraction, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Just a few more details', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 10), const Text('We need this to set up sessions for your child.'), const SizedBox(height: 32), TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'), validator: Validators.phone), const SizedBox(height: 16), TextFormField(controller: childName, decoration: const InputDecoration(labelText: "Child's Name"), validator: Validators.required), const SizedBox(height: 16), TextFormField(controller: childAge, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Child's Age"), validator: Validators.age), const SizedBox(height: 28), JbbButton(label: 'Continue', busy: busy, onPressed: save)]))));
  }
}
