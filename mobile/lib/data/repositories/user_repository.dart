import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'cached_repository.dart';
class UserRepository extends CachedRepository {
  Stream<Map<String, dynamic>> watch() => watchDocument(db.doc('users/$uid'), 'profile');
  Stream<Map<String, dynamic>> settings() => watchDocument(db.doc('gymSettings/config'), 'settings');
  Future<void> save(Map<String, dynamic> values) => db.doc('users/$uid').update({...values, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> changeEmail(String email) => FirebaseAuth.instance.currentUser!.verifyBeforeUpdateEmail(email);
  Future<void> uploadAvatar(File file) async {
    if (await file.length() > 5 * 1024 * 1024) throw const FormatException('Image must be smaller than 5 MB');
    final image = FirebaseStorage.instance.ref('avatars/$uid/profile.jpg');
    await image.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    await save({'avatarUrl': await image.getDownloadURL()});
  }
}
