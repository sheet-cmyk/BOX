import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
class JbbLoading extends StatelessWidget {
  const JbbLoading({super.key});
  @override Widget build(BuildContext context) => Shimmer.fromColors(baseColor: const Color(0xFF181818), highlightColor: const Color(0xFF2A2A2A), child: Column(children: List.generate(3, (_) => Container(height: 112, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))))));
}
