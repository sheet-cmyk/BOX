import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/jbb_card.dart';
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});
  @override Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, childAspectRatio: 1.65, mainAxisSpacing: 0, crossAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [for (final item in [('Book Class',Icons.sports_mma,'/book'),('Class Schedule',Icons.calendar_month,'/schedule'),('Membership',Icons.workspace_premium,'/membership'),('Contact',Icons.phone_outlined,'/contact')]) JbbCard(onTap: () => context.go(item.$3), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.$2, color: Colors.red), const SizedBox(height: 8), Text(item.$1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))]))]);
}
