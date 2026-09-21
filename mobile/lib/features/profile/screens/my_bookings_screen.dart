import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../booking/providers/booking_provider.dart';
import '../providers/profile_provider.dart';
class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});
  @override ConsumerState<MyBookingsScreen> createState() => _BookingsState();
}
class _BookingsState extends ConsumerState<MyBookingsScreen> {
  int selected = 0;
  final pending = <String>{};
  Future<bool> cancel(Map<String, dynamic> booking) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Cancel this booking?'), content: const Text('Your reserved session credit will be released.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep booking')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel booking'))]));
    if (confirmed != true || !mounted) return false;
    setState(() => pending.add(booking['id']));
    try { await ref.read(bookingRepositoryProvider).cancel(booking['id']); if (mounted) showMessage(context, 'Booking cancelled.'); }
    catch (e) { if (mounted) showMessage(context, friendlyError(e)); }
    finally { if (mounted) setState(() => pending.remove(booking['id'])); }
    return false;
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('My Bookings')), body: ListView(padding: const EdgeInsets.all(16), children: [SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Upcoming')), ButtonSegment(value: 1, label: Text('Past'))], selected: {selected}, onSelectionChanged: (s) => setState(() => selected = s.first)), const SizedBox(height: 20), ref.watch(bookingsProvider).when(data: (rows) {
    final items = rows.where((b) { final upcoming = b['status'] == 'confirmed' && readDate(b['date']).isAfter(DateTime.now()); return selected == 0 ? upcoming : !upcoming; }).toList();
    if (items.isEmpty) return const JbbEmptyState(message: 'No bookings here yet.');
    return Column(children: items.map((b) { final hours = ref.watch(settingsProvider).value?['cancellationPolicyHours'] ?? 24; final allowed = b['status'] == 'confirmed' && readDate(b['date']).difference(DateTime.now()).inSeconds >= hours * 3600; return Dismissible(key: ValueKey(b['id']), direction: allowed ? DismissDirection.endToStart : DismissDirection.none, confirmDismiss: (_) => cancel(b), background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.all(20), child: const Icon(Icons.cancel)), child: JbbCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b['className'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('${dateLabel(readDate(b['date']))} · ${timeLabel(readDate(b['date']))} PT'), const SizedBox(height: 8), Text(b['status'].toString().toUpperCase(), style: TextStyle(color: b['status'] == 'cancelled' ? Colors.red : Colors.green, fontSize: 12)), if (allowed) TextButton(onPressed: pending.contains(b['id']) ? null : () => cancel(b), child: const Text('Cancel booking')), if (!allowed && b['status'] == 'confirmed') const Padding(padding: EdgeInsets.only(top: 8), child: Text('For late changes, contact the gym.', style: TextStyle(color: Colors.grey)))]))); }).toList());
  }, error: (e, s) => JbbEmptyState(message: friendlyError(e), onRetry: () => ref.invalidate(bookingsProvider)), loading: () => const JbbLoading())]));
}
