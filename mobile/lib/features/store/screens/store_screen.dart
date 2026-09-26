import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/store_provider.dart';
import 'product_editor_screen.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(profileProvider).value?['role'] == 'admin';
    final products = ref.watch(
      isAdmin ? productsAdminProvider : productsProvider,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Store')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProductEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
      body: PageContent(
        children: [
          products.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort(
                  (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(
                    b['sortOrder'] as num? ?? 0,
                  ),
                );
              if (sorted.isEmpty) {
                return JbbEmptyState(
                  message: isAdmin
                      ? 'No products yet. Tap Add Product to create your first one.'
                      : 'Products will appear here when available.',
                );
              }
              return Column(
                children: [
                  for (final product in sorted)
                    JbbCard(
                      onTap: isAdmin
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductEditorScreen(product: product),
                              ),
                            )
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (product['imageUrl'] ?? '').isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product['imageUrl'],
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const _ProductPlaceholder(),
                                  )
                                : const _ProductPlaceholder(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (isAdmin && product['isActive'] != true)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text(
                                          'HIDDEN',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if ((product['description'] ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    product['description'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  product['priceLabel'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  if (!isAdmin) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/contact'),
                      child: const Text('Ask the gym to order an item'),
                    ),
                  ],
                ],
              );
            },
            error: (e, s) => JbbEmptyState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(
                isAdmin ? productsAdminProvider : productsProvider,
              ),
            ),
            loading: () => const JbbLoading(),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    color: Colors.white10,
    child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
  );
}
