import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/review_model.dart';
import 'star_rating.dart';

/// Overall rating summary: big average number, stars, review count, and a
/// per-star distribution bar chart (5 stars down to 1).
class RatingSummaryHeader extends StatelessWidget {
  const RatingSummaryHeader({super.key, required this.stats});

  final ReviewStats stats;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: stats.count == 0
        ? const Text(
            'No reviews yet. Be the first to share your experience!',
            style: TextStyle(color: AppColors.muted),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats.average.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StarRating(rating: stats.average, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.count} ${stats.count == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      _DistributionBar(
                        star: star,
                        count: stats.countFor(star),
                        total: stats.count,
                      ),
                  ],
                ),
              ),
            ],
          ),
  );
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.star,
    required this.count,
    required this.total,
  });

  final int star;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text(
              '$star',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 10, color: AppColors.red),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.red),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
