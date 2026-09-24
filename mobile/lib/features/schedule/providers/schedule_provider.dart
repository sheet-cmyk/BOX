import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../data/repositories/schedule_repository.dart';
import '../../auth/providers/auth_provider.dart';

final scheduleRepositoryProvider = Provider((ref) => ScheduleRepository());
final classesProvider = StreamProvider((ref) {
  if (ref.watch(authProvider).value == null) {
    return const Stream<List<Map<String, dynamic>>>.empty();
}
  return ref.watch(scheduleRepositoryProvider).classes();
});
final scheduleProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, day) {
      if (ref.watch(authProvider).value == null) return Stream.value([]);
      final d = DateTime.parse(day),
          location = tz.getLocation('America/Los_Angeles');
      final from = tz.TZDateTime(location, d.year, d.month, d.day),
          to = tz.TZDateTime(location, d.year, d.month, d.day + 1);
      return ref.watch(scheduleRepositoryProvider).watch(from, to);
    });
final sessionProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).detail(id),
);
