import 'cached_repository.dart';
class NotificationRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> watch() => watchQuery(db.collection('notifications').where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).limit(100), 'notifications');
  Future<void> markRead(String id) => db.doc('notifications/$id').update({'isRead': true});
}
