import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../membership/providers/membership_provider.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Payments')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ref
            .watch(paymentsProvider)
            .when(
              data: (rows) => rows.isEmpty
                  ? const JbbEmptyState(message: 'No payments yet.')
                  : Column(
                      children: rows
                          .map(
                            (p) => JbbCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '\$${(p['amount'] / 100).toStringAsFixed(2)}',
                                ),
                                subtitle: Text(
                                  '${dateLabel(readDate(p['createdAt']))} · ${p['paymentMethod']}',
                                ),
                                trailing: Text(p['status']),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              error: (e, s) => JbbEmptyState(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(paymentsProvider),
              ),
              loading: () => const JbbLoading(),
            ),
      ],
    ),
  );
}
