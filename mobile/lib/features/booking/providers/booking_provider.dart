import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../auth/providers/auth_provider.dart';
final bookingRepositoryProvider = Provider((ref) => BookingRepository());
final bookingsProvider = StreamProvider((ref) {
  if (ref.watch(authProvider).value == null) return const Stream<List<Map<String, dynamic>>>.empty();
  return ref.watch(bookingRepositoryProvider).watch();
});
