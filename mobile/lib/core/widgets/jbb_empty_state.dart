import 'package:flutter/material.dart';

class JbbEmptyState extends StatelessWidget {
  const JbbEmptyState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.sports_mma_outlined, size: 38, color: Colors.grey),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
