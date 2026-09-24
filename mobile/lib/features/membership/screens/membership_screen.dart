import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/services/stripe_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../providers/membership_provider.dart';
import '../widgets/plan_card.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});
  @override
  ConsumerState<MembershipScreen> createState() => _MembershipState();
}

class _MembershipState extends ConsumerState<MembershipScreen> {
  String selected = 'ten';
  final stripe = StripeService();
  bool busy = false;
  Future<void> purchase() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.isAnonymous) {
        await ref.read(authRepositoryProvider).googleSignIn();
        if (mounted) showMessage(context, 'Signed in. Complete your profile, then choose your plan.');
        return;
      }
      final profile = (await FirebaseFirestore.instance.doc('users/${authUser.uid}').get()).data();
      if (!mounted) return;
      if (profile == null || !isProfileComplete(profile)) {
        final completed = await context.push<bool>('/complete-profile');
        if (completed != true || !mounted) return;
      }
      final message = await stripe.purchase(selected);
      if (mounted) showMessage(context, message);
    } catch (e) {
      if (mounted) { showMessage(context, e is FormatException ? e.message : friendlyError(e)); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    return PageContent(
      title: 'Choose Your Plan',
      children: [
        const Wrap(
          spacing: 8,
          children: [
            Chip(label: Text('Build Confidence')),
            Chip(label: Text('Get Stronger')),
            Chip(label: Text('Real Progress')),
          ],
        ),
        const SizedBox(height: 16),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '${user['sessionsRemaining']} sessions remaining · ${user['sessionsReserved'] ?? 0} reserved',
            ),
          ),
        ref
            .watch(plansProvider)
            .when(
              data: (rows) {
                final plans = [...rows]
                  ..sort(
                    (a, b) => (a['sortOrder'] as num).compareTo(
                      b['sortOrder'] as num,
                    ),
                  );
                if (plans.isNotEmpty &&
                    !plans.any((p) => p['id'] == selected)) {
                  selected = plans.first['id'];
                }
                return Column(
                  children: [
                    for (final plan in plans)
                      PlanCard(
                        plan: plan,
                        selected: selected == plan['id'],
                        onTap: busy
                            ? () {}
                            : () => setState(() {
                                selected = plan['id'];
                              }),
                      ),
                    if (plans.isEmpty)
                      const JbbEmptyState(
                        message:
                            'Membership plans will appear here when available.',
                      ),
                    if (plans.any((p) => p['id'] == selected))
                      JbbButton(
                        label: 'Continue  →',
                        busy: busy,
                        onPressed: purchase,
                      ),
                  ],
                );
              },
              error: (e, s) => JbbEmptyState(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(plansProvider),
              ),
              loading: () => const JbbLoading(),
            ),
      ],
    );
  }
}
