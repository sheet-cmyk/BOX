import 'package:cloud_firestore/cloud_firestore.dart';
import 'cached_repository.dart';

class ScheduleRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> watch(DateTime from, DateTime to) =>
      watchQuery(
        db
            .collection('schedule')
            .where('isCancelled', isEqualTo: false)
            .where('date', isGreaterThanOrEqualTo: from)
            .where('date', isLessThan: to)
            .orderBy('date'),
        'schedule:${from.toIso8601String()}',
      );

  /// Date of the next upcoming (non-cancelled) session, or null if none is
  /// scheduled. Used to default the schedule view to a day that actually
  /// has a class instead of landing on an empty "today".
  Future<DateTime?> nextSessionDate() async {
    final snapshot = await db
        .collection('schedule')
        .where('isCancelled', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return (snapshot.docs.first.data()['date'] as Timestamp).toDate();
  }
  Stream<List<Map<String, dynamic>>> classes() => watchQuery(
    db.collection('classes').where('isActive', isEqualTo: true),
    'classes',
  );
  Stream<Map<String, dynamic>> detail(String id) =>
      watchDocument(db.doc('schedule/$id'), 'session:$id');
}
