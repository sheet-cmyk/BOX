import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../profile/providers/profile_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/next_session_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/programs_section.dart';
import '../widgets/youtube_background_player.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value,
        next = ref.watch(nextBookingProvider);
    final videoId = extractYoutubeId(
      ref.watch(settingsProvider).value?['promoVideoUrl'] ?? '',
    );
    return PageContent(
      showHeader: false,
      refresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(bookingsProvider);
        await ref.read(bookingsProvider.future);
      },
      children: [
        HomeHeroBanner(
          name: (user?['fullName'] ?? 'Champion').toString().split(' ').first,
        ),
        if (videoId != null) ...[
          const SizedBox(height: 16),
          YoutubeBackgroundPlayer(videoId: videoId),
        ],
        const SizedBox(height: 20),
        if (next != null)
          NextSessionCard(booking: next)
        else
          const JbbEmptyState(
            message: 'Your next session starts with a booking.',
          ),
        const QuickActionsGrid(),
        const SizedBox(height: 18),
        const ProgramsSection(),
      ],
    );
  }
}
