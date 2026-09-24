import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final authProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.userChanges(),
);
