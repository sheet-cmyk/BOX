import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../providers/review_provider.dart';
import '../widgets/rating_summary_header.dart';
import '../widgets/review_card.dart';
import '../widgets/review_form_sheet.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReview = ref.watch(myReviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reviewsProvider);
          ref.invalidate(reviewStatsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            ref
                .watch(reviewStatsProvider)
                .when(
                  data: (stats) => RatingSummaryHeader(stats: stats),
                  error: (e, s) => JbbEmptyState(message: friendlyError(e)),
                  loading: () => const JbbLoading(),
                ),
            JbbButton(
              label: myReview == null ? 'Write a Review' : 'Edit Your Review',
              onPressed: () => showReviewFormSheet(context, existing: myReview),
            ),
            const SizedBox(height: 24),
            ref
                .watch(reviewsProvider)
                .when(
                  data: (reviews) => reviews.isEmpty
                      ? const JbbEmptyState(
                          message:
                              'No reviews yet. Be the first to share your experience!',
                        )
                      : Column(
                          children: [
                            for (final review in reviews)
                              ReviewCard(
                                review: review,
                                onDelete: myReview?.id == review.id
                                    ? () async {
                                        try {
                                          await ref
                                              .read(reviewRepositoryProvider)
                                              .deleteReview();
                                          if (context.mounted) {
                                            showMessage(
                                              context,
                                              'Review deleted.',
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            showMessage(
                                              context,
                                              friendlyError(e),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                              ),
                          ],
                        ),
                  error: (e, s) => JbbEmptyState(
                    message: friendlyError(e),
                    onRetry: () => ref.invalidate(reviewsProvider),
                  ),
                  loading: () => const JbbLoading(),
                ),
          ],
        ),
      ),
    );
  }
}
