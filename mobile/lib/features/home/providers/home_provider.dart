import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../booking/providers/booking_provider.dart';

final nextBookingProvider = Provider<Map<String, dynamic>?>((ref) {
  final items = ref.watch(bookingsProvider).value ?? [];
  final upcoming =
      items
          .where(
            (b) =>
                b['status'] == 'confirmed' &&
                readDate(b['date']).isAfter(DateTime.now()),
          )
          .toList()
        ..sort((a, b) => readDate(a['date']).compareTo(readDate(b['date'])));
  return upcoming.isEmpty ? null : upcoming.first;
});
