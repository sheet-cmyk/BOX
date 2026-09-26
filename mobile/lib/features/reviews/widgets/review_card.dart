import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/review_model.dart';
import 'star_rating.dart';

/// Displays a single review: avatar, name, star rating, date and comment.
/// Pass [onDelete] to show a delete action (only the review's own author
/// should be able to delete it — the caller decides when to pass this).
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.onDelete});

  final ReviewModel review;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.border,
              backgroundImage: review.userAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(review.userAvatarUrl)
                  : null,
              child: review.userAvatarUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.muted, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StarRating(rating: review.rating.toDouble(), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel(review.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.muted,
                ),
                tooltip: 'Delete your review',
                onPressed: onDelete,
              ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(height: 1.5)),
        ],
      ],
    ),
  );
}
