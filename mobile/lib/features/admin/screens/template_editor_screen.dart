import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../providers/admin_provider.dart';

const _weekdays = [
  (1, 'Monday'),
  (2, 'Tuesday'),
  (3, 'Wednesday'),
  (4, 'Thursday'),
  (5, 'Friday'),
  (6, 'Saturday'),
  (7, 'Sunday'),
];

class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, this.template});
  final Map<String, dynamic>? template;
  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<TemplateEditorScreen> {
  final form = GlobalKey<FormState>();
  late String? classId = widget.template?['classId'];
  late int dayOfWeek = widget.template?['dayOfWeek'] ?? 1;
  late final startTime = TextEditingController(
    text: widget.template?['startTime'] ?? '16:00',
  );
  late final maxSpots = TextEditingController(
    text: (widget.template?['maxSpots'] ?? 12).toString(),
  );
  late bool isActive = widget.template?['isActive'] ?? true;
  bool busy = false;

  @override
  void dispose() {
    startTime.dispose();
    maxSpots.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || classId == null) return;
    setState(() => busy = true);
    final id = widget.template?['id'] ?? '${classId}_$dayOfWeek';
    try {
      await ref.read(adminRepositoryProvider).saveTemplate(id, {
        'classId': classId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime.text.trim(),
        'maxSpots': int.parse(maxSpots.text),
        'isActive': isActive,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this class time?'),
        content: const Text(
          'Future sessions already generated for it stay bookable; new ones stop being created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteTemplate(widget.template!['id']);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Add Class Time' : 'Edit Class Time'),
        actions: [
          if (widget.template != null)
            IconButton(
              onPressed: busy ? null : delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: classId,
                decoration: const InputDecoration(labelText: 'Program'),
                items: [
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['className'] ?? c['id']),
                    ),
                ],
                onChanged: (v) => setState(() => classId = v),
                validator: (v) => v == null ? 'Choose a program' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: dayOfWeek,
                decoration: const InputDecoration(labelText: 'Day of week'),
                items: [
                  for (final d in _weekdays)
                    DropdownMenuItem(value: d.$1, child: Text(d.$2)),
                ],
                onChanged: (v) => setState(() => dayOfWeek = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: startTime,
                decoration: const InputDecoration(
                  labelText: 'Start time (24h, e.g. 16:00)',
                ),
                validator: (v) =>
                    RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                    ? null
                    : 'Use 24-hour HH:mm, e.g. 16:00',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: maxSpots,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max spots'),
                validator: (v) =>
                    int.tryParse(v ?? '') != null && int.parse(v!) > 0
                    ? null
                    : 'Enter a valid number',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active (generates weekly sessions)'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
              const SizedBox(height: 16),
              JbbButton(
                label: widget.template == null ? 'Add Class Time' : 'Save Changes',
                busy: busy,
                onPressed: save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
