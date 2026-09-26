import 'package:cloud_functions/cloud_functions.dart';
import 'cached_repository.dart';

/// Data-access layer for the "Client Reviews & Ratings" feature.
///
/// Backend: Cloud Firestore + Cloud Functions (already configured in this
/// project's Firebase console). Reads go straight to Firestore for live
/// updates; writes go through Cloud Functions so ratings can be validated
/// and the aggregate stats document is always kept correct.
///
/// To point this at a different backend (e.g. Supabase) later, this is the
/// only file that needs to change — every screen/widget in
/// `lib/features/reviews` only ever talks to [ReviewRepository], never to
/// Firestore or Cloud Functions directly.
class ReviewRepository extends CachedRepository {
  /// Most recent reviews, newest first.
  Stream<List<Map<String, dynamic>>> reviews() => watchQuery(
    db.collection('reviews').orderBy('createdAt', descending: true).limit(50),
    'reviews',
  );

  /// Aggregate rating summary (average, count, per-star distribution).
  /// Falls back to an empty summary if no review has ever been submitted.
  Stream<Map<String, dynamic>> stats() => db
      .doc('reviewStats/summary')
      .snapshots()
      .map((snapshot) => normalize(snapshot.data()) as Map<String, dynamic>? ?? const {});

  /// Creates or updates the current user's review. A user has at most one
  /// review; calling this again edits it in place.
  Future<void> submitReview({required int rating, required String comment}) =>
      FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'rating': rating,
        'comment': comment,
      });

  /// Deletes the current user's own review, if any.
  Future<void> deleteReview() =>
      FirebaseFunctions.instance.httpsCallable('deleteReview').call();
}
