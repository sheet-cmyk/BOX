import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class JbbCard extends StatelessWidget {
  const JbbCard({super.key, required this.child, this.selected = false, this.onTap});
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.red : AppColors.border, width: selected ? 2 : 1)), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(16), child: child))));
}
