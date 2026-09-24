import 'package:cloud_functions/cloud_functions.dart';
import 'cached_repository.dart';

class BookingRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> watch() => watchQuery(
    db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(200),
    'bookings',
  );
  Future<String> create(String scheduleId) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('createBooking')
        .call({'scheduleId': scheduleId});
    return result.data['bookingId'] as String;
  }

  Future<void> cancel(String bookingId) async {
    await FirebaseFunctions.instance.httpsCallable('cancelBooking').call({
      'bookingId': bookingId,
      'reason': 'Cancelled by member',
    });
  }
}
