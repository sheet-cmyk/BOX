import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'jbb_card.dart';

class JbbClassCard extends StatelessWidget {
  const JbbClassCard({super.key, required this.session, required this.program});
  final Map<String, dynamic> session, program;
  @override
  Widget build(BuildContext context) {
    final spots =
        (session['maxSpots'] as num) - (session['bookedSpots'] as num);
    return JbbCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: 'class-${session['id']}',
              child: Image.asset(
                'assets/images/photos/photo_kid_boxing.png',
                width: 66,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session['startTime']} – ${session['endTime']}',
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  program['className'] ?? 'Boxing class',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  program['ageGroup'] ?? '',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  spots > 0 ? '$spots spots available' : 'Fully booked',
                  style: TextStyle(
                    color: spots > 0 ? AppColors.green : AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 42),
                padding: EdgeInsets.zero,
              ),
              onPressed: spots > 0
                  ? () => context.push('/booking/${session['id']}')
                  : null,
              child: const Text('Book'),
            ),
          ),
        ],
      ),
    );
  }
}
