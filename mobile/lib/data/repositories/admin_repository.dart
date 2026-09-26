import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'cached_repository.dart';

/// Admin-only data access for the in-app dashboard: membership plan
/// prices and class schedule times. Firestore rules already restrict
/// writes to these collections to role:'admin' accounts, matching the
/// same pattern the web admin panel uses.
class AdminRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> plans() =>
      watchQuery(db.collection('membershipPlans'), 'admin_plans');
  Stream<List<Map<String, dynamic>>> templates() =>
      watchQuery(db.collection('recurringTemplates'), 'admin_templates');

  Future<void> savePlan(String id, Map<String, dynamic> values) =>
      db.doc('membershipPlans/$id').set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveTemplate(String id, Map<String, dynamic> values) =>
      db.doc('recurringTemplates/$id').set(values, SetOptions(merge: true));

  Future<void> deleteTemplate(String id) =>
      db.doc('recurringTemplates/$id').delete();

  Future<void> savePromoVideoUrl(String url) =>
      db.doc('gymSettings/config').set({
        'promoVideoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Verifies the admin PIN server-side; the PIN itself is never sent to
  /// or readable by any client.
  Future<void> verifyPin(String pin) =>
      FirebaseFunctions.instance.httpsCallable('verifyAdminPin').call({
        'pin': pin,
      });
}
