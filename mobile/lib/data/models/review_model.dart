import '../../core/utils/date_utils.dart';

/// A single client review, stored in Firestore at `reviews/{userId}`.
///
/// Each user has at most one review (the document id is their uid), so
/// submitting a new review updates the existing one instead of creating a
/// duplicate. Writes always go through the `submitReview` / `deleteReview`
/// Cloud Functions (see [ReviewRepository]) so the aggregate rating stats
/// in `reviewStats/summary` stay correct — never write to this collection
/// directly from the client.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;

  /// Whole-star rating from 1 to 5.
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
    id: map['id'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    userName: map['userName'] as String? ?? 'Member',
    userAvatarUrl: map['userAvatarUrl'] as String? ?? '',
    rating: (map['rating'] as num?)?.toInt() ?? 0,
    comment: map['comment'] as String? ?? '',
    createdAt: readDate(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Aggregate rating stats, stored at `reviewStats/summary` and kept in sync
/// server-side by the `submitReview` / `deleteReview` Cloud Functions.
class ReviewStats {
  const ReviewStats({
    required this.count,
    required this.average,
    required this.distribution,
  });

  final int count;
  final double average;

  /// Number of reviews for each star rating, keyed '1'..'5'.
  final Map<String, int> distribution;

  static const empty = ReviewStats(count: 0, average: 0, distribution: {});

  factory ReviewStats.fromMap(Map<String, dynamic> map) => ReviewStats(
    count: (map['count'] as num?)?.toInt() ?? 0,
    average: (map['average'] as num?)?.toDouble() ?? 0,
    distribution: (map['distribution'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        ) ??
        const {},
  );

  int countFor(int star) => distribution['$star'] ?? 0;
}
