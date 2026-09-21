import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
class ProgramsSection extends StatelessWidget {
  const ProgramsSection({super.key});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Our Programs', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), for (final item in [(AppAssets.junior,'Junior Boxing — Kids & Teens'),(AppAssets.group,'Group Training — 3–4 People')]) Padding(padding: const EdgeInsets.only(bottom: 12), child: Semantics(button: true, label: 'View ${item.$2} schedule', child: InkWell(onTap: () => context.go('/schedule'), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(item.$1, fit: BoxFit.fitWidth, width: double.infinity)))))]);
}
