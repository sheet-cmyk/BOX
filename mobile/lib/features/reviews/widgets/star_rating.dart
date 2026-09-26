import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Renders 1-5 stars. Pass [onChanged] to make it a tappable input (used in
/// the review form); leave it null for a read-only display (review cards,
/// rating summary). Supports half-star rendering for averages like 4.3.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.onChanged,
  });

  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  bool get _interactive => onChanged != null;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var star = 1; star <= 5; star++)
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: GestureDetector(
            onTap: _interactive ? () => onChanged!(star) : null,
            child: Icon(
              rating >= star
                  ? Icons.star
                  : (rating >= star - 0.5 ? Icons.star_half : Icons.star_border),
              color: AppColors.red,
              size: size,
            ),
          ),
        ),
    ],
  );
}
