import 'package:flutter/material.dart';
import '../../../core/widgets/jbb_card.dart';
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.selected, required this.onTap});
  final Map<String, dynamic> plan;
  final bool selected;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Semantics(selected: selected, button: true, child: JbbCard(selected: selected, onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (plan['isRecommended'] == true) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('RECOMMENDED', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))), Row(children: [Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? Colors.red : Colors.grey), const SizedBox(width: 12), Expanded(child: Text(plan['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))), Text(plan['priceLabel'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]), Padding(padding: const EdgeInsets.only(left: 36, top: 8), child: Text(plan['perSessionLabel'] ?? '', style: const TextStyle(color: Colors.grey)))])));
}
