import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../profile/providers/profile_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/welcome_header.dart';
import '../widgets/next_session_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/programs_section.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value, next = ref.watch(nextBookingProvider);
    return PageContent(refresh: () async { ref.invalidate(profileProvider); ref.invalidate(bookingsProvider); await ref.read(bookingsProvider.future); }, children: [WelcomeHeader(name: (user?['fullName'] ?? 'Champion').toString().split(' ').first), if (next != null) NextSessionCard(booking: next) else const JbbEmptyState(message: 'Your next session starts with a booking.'), const QuickActionsGrid(), const SizedBox(height: 18), const ProgramsSection()]);
  }
}
