import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Welcome Back, '),
              TextSpan(
                text: '$name!',
                style: const TextStyle(color: AppColors.red),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Keep training. Keep improving.',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
