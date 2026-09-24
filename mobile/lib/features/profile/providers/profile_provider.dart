import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/providers/auth_provider.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());
final profileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  if (ref.watch(authProvider).value == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watch();
});
final settingsProvider = StreamProvider(
  (ref) => ref.watch(userRepositoryProvider).settings(),
);
final notificationsProvider = StreamProvider((ref) {
  if (ref.watch(authProvider).value == null) {
    return const Stream<List<Map<String, dynamic>>>.empty();
}
  return NotificationRepository().watch();
});
