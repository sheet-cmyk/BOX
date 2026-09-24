import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/waiver_screen.dart';
import '../providers/booking_provider.dart';

class BookClassScreen extends ConsumerStatefulWidget {
  const BookClassScreen({super.key, required this.scheduleId});
  final String scheduleId;
  @override
  ConsumerState<BookClassScreen> createState() => _BookClassState();
}

class _BookClassState extends ConsumerState<BookClassScreen> {
  bool busy = false;
  Future<void> confirm() async {
    final user = ref.read(profileProvider).value;
    final waiver = ref.read(waiverProvider).value?.data();
    if (waiver?['published'] == true &&
        waiver?['requiredOnBooking'] == true &&
        (user?['waiverVersion'] != waiver?['version'] ||
            user?['waiverParticipantName'] != user?['childName']?.trim() ||
            user?['waiverParticipantAge'] != user?['childAge'])) {
      context.push('/waiver');
      return;
    }
    if ((user?['sessionsRemaining'] ?? 0) - (user?['sessionsReserved'] ?? 0) <
        1) {
      context.go('/membership');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(bookingRepositoryProvider).create(widget.scheduleId);
      if (mounted) context.go('/booking-confirmed');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(waiverProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Book Class')),
      body: ref
          .watch(sessionProvider(widget.scheduleId))
          .when(
            data: (session) {
              final programs = ref.watch(classesProvider).value ?? [],
                  program = programs.firstWhere(
                    (c) => c['id'] == session['classId'],
                    orElse: () => <String, dynamic>{},
                  );
              final spots = session['maxSpots'] - session['bookedSpots'];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'class-${widget.scheduleId}',
                      child: Image.asset(
                        'assets/images/photos/photo_kid_boxing.png',
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  JbbCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program['className'] ?? 'Boxing class',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(program['ageGroup'] ?? ''),
                        const SizedBox(height: 22),
                        for (final item in [
                          ('DATE', dateLabel(readDate(session['date']))),
                          (
                            'TIME',
                            '${timeLabel(readDate(session['date']))} – ${timeLabel(readDate(session['endAt']))} PT',
                          ),
                          (
                            'LOCATION',
                            program['address'] ?? '3200 Naglee Rd, Tracy, CA',
                          ),
                          ('AVAILABILITY', '$spots spots'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$1,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(item.$2),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  JbbButton(
                    label: 'Confirm Booking  ›',
                    busy: busy,
                    onPressed:
                        spots > 0 &&
                            session['isCancelled'] != true &&
                            readDate(session['date']).isAfter(DateTime.now())
                        ? confirm
                        : null,
                  ),
                ],
              );
            },
            error: (e, s) => JbbEmptyState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(sessionProvider(widget.scheduleId)),
            ),
            loading: () => const JbbLoading(),
          ),
    );
  }
}
