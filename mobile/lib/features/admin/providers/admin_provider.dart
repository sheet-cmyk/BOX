import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());
final adminPlansProvider = StreamProvider(
  (ref) => ref.watch(adminRepositoryProvider).plans(),
);
final adminTemplatesProvider = StreamProvider(
  (ref) => ref.watch(adminRepositoryProvider).templates(),
);
