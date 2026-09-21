import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/membership_repository.dart';
import '../../auth/providers/auth_provider.dart';
final plansProvider = StreamProvider((ref) => MembershipRepository().plans());
final paymentsProvider = StreamProvider((ref) {
  if (ref.watch(authProvider).value == null) return const Stream<List<Map<String, dynamic>>>.empty();
  return MembershipRepository().payments();
});
