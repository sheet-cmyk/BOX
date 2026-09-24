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
  Stream<List<Map<String, dynamic>>> classes() => watchQuery(
    db.collection('classes').where('isActive', isEqualTo: true),
    'classes',
  );
  Stream<Map<String, dynamic>> detail(String id) =>
      watchDocument(db.doc('schedule/$id'), 'session:$id');
}
