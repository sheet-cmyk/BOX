import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../home/widgets/youtube_background_player.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/admin_provider.dart';
import 'plan_editor_screen.dart';
import 'template_editor_screen.dart';

const _weekdayNames = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(adminPlansProvider);
    final templates = ref.watch(adminTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          JbbCard(
            onTap: () => context.push('/store'),
            child: const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: AppColors.red),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Manage Store Products',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _PromoVideoSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Membership Prices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          plans.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort(
                  (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(
                    b['sortOrder'] as num? ?? 0,
                  ),
                );
              return Column(
                children: [
                  for (final plan in sorted)
                    JbbCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlanEditorScreen(plan: plan),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${plan['priceLabel'] ?? ''} · ${plan['isActive'] == true ? 'Active' : 'Hidden'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text('Could not load plans: $e'),
            loading: () => const JbbLoading(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Class Schedule Times',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TemplateEditorScreen(),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          templates.when(
            data: (rows) {
              final sorted = [...rows]..sort((a, b) {
                final dayCompare = (a['dayOfWeek'] as num).compareTo(
                  b['dayOfWeek'] as num,
                );
                return dayCompare != 0
                    ? dayCompare
                    : (a['startTime'] as String).compareTo(
                        b['startTime'] as String,
                      );
              });
              if (sorted.isEmpty) {
                return const Text(
                  'No class times set up yet.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Column(
                children: [
                  for (final t in sorted)
                    JbbCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TemplateEditorScreen(template: t),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weekdayNames[t['dayOfWeek']] ?? ''} · ${t['startTime']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${t['classId']} · ${t['maxSpots']} spots · ${t['isActive'] == true ? 'Active' : 'Paused'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text('Could not load schedule times: $e'),
            loading: () => const JbbLoading(),
          ),
        ],
      ),
    );
  }
}

/// Lets the admin set the YouTube video that plays silently and on loop
/// near the top of Home. Leave the field empty to hide it.
class _PromoVideoSection extends ConsumerStatefulWidget {
  const _PromoVideoSection();
  @override
  ConsumerState<_PromoVideoSection> createState() => _PromoVideoSectionState();
}

class _PromoVideoSectionState extends ConsumerState<_PromoVideoSection> {
  final url = TextEditingController();
  bool loaded = false, busy = false;

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final trimmed = url.text.trim();
    if (trimmed.isNotEmpty && extractYoutubeId(trimmed) == null) {
      showMessage(context, 'That doesn\'t look like a valid YouTube link.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).savePromoVideoUrl(trimmed);
      if (mounted) {
        showMessage(
          context,
          trimmed.isEmpty ? 'Video removed from Home.' : 'Video saved.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!loaded && settings != null) {
      url.text = settings['promoVideoUrl'] ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo Video',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Plays silently on loop at the top of Home. Paste a YouTube link, or clear it to hide the video.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: url,
            decoration: const InputDecoration(
              labelText: 'YouTube link',
              hintText: 'https://www.youtube.com/watch?v=...',
            ),
          ),
          const SizedBox(height: 12),
          JbbButton(label: 'Save Video', busy: busy, onPressed: save),
        ],
      ),
    );
  }
}
