import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'cached_repository.dart';

class ProductRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> products() => watchQuery(
    db.collection('products').where('isActive', isEqualTo: true),
    'products',
  );
  Stream<List<Map<String, dynamic>>> productsAdmin() =>
      watchQuery(db.collection('products'), 'products_admin');
  Future<String> uploadImage(String productId, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Image must be smaller than 5 MB');
    }
    final image = FirebaseStorage.instance.ref('gym/products/$productId');
    await image.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return image.getDownloadURL();
  }
  Future<void> save(String id, Map<String, dynamic> values) =>
      db.doc('products/$id').set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  Future<void> delete(String id) => db.doc('products/$id').delete();
}
