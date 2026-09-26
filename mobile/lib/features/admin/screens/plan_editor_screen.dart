import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/admin_provider.dart';

class PlanEditorScreen extends ConsumerStatefulWidget {
  const PlanEditorScreen({super.key, required this.plan});
  final Map<String, dynamic> plan;
  @override
  ConsumerState<PlanEditorScreen> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<PlanEditorScreen> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.plan['name']);
  late final description = TextEditingController(
    text: widget.plan['description'],
  );
  late final perSessionLabel = TextEditingController(
    text: widget.plan['perSessionLabel'],
  );
  late final price = TextEditingController(
    text: widget.plan['price'] != null
        ? (widget.plan['price'] / 100).toString()
        : '',
  );
  late bool isActive = widget.plan['isActive'] ?? true;
  late bool isRecommended = widget.plan['isRecommended'] ?? false;
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    perSessionLabel.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final cents = (double.parse(price.text) * 100).round();
    try {
      await ref.read(adminRepositoryProvider).savePlan(widget.plan['id'], {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'perSessionLabel': perSessionLabel.text.trim(),
        'price': cents,
        'priceLabel': '\$${(cents / 100).toStringAsFixed(2)}',
        'isActive': isActive,
        'isRecommended': isRecommended,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Edit ${widget.plan['name'] ?? 'Plan'}')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Plan name'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: perSessionLabel,
              decoration: const InputDecoration(
                labelText: 'Rate description (e.g. "\$70 / session")',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price in USD'),
              validator: (v) =>
                  double.tryParse(v ?? '') != null && double.parse(v!) > 0
                  ? null
                  : 'Enter a valid price',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible to members)'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recommended'),
              value: isRecommended,
              onChanged: (v) => setState(() => isRecommended = v),
            ),
            const SizedBox(height: 16),
            JbbButton(label: 'Save Plan', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}
