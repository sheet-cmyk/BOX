import 'cached_repository.dart';

class MembershipRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> plans() => watchQuery(
    db.collection('membershipPlans').where('isActive', isEqualTo: true),
    'plans',
  );
  Stream<List<Map<String, dynamic>>> payments() => watchQuery(
    db
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100),
    'payments',
  );
}
