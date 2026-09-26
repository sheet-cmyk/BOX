import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';
import '../../auth/providers/auth_provider.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

final reviewsProvider = StreamProvider<List<ReviewModel>>(
  (ref) => ref
      .watch(reviewRepositoryProvider)
      .reviews()
      .map((rows) => rows.map(ReviewModel.fromMap).toList()),
);

final reviewStatsProvider = StreamProvider<ReviewStats>(
  (ref) => ref
      .watch(reviewRepositoryProvider)
      .stats()
      .map(ReviewStats.fromMap),
);

/// The signed-in user's own review, derived from [reviewsProvider]. Null
/// while loading, unauthenticated, or if the user hasn't reviewed yet.
final myReviewProvider = Provider<ReviewModel?>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  final reviews = ref.watch(reviewsProvider).value;
  if (uid == null || reviews == null) return null;
  for (final review in reviews) {
    if (review.userId == uid) return review;
  }
  return null;
});
