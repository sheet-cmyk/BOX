import 'cached_repository.dart';

class ProductRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> products() => watchQuery(
    db.collection('products').where('isActive', isEqualTo: true),
    'products',
  );
}
