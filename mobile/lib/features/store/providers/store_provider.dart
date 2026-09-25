import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());
final productsProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).products(),
);
final productsAdminProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).productsAdmin(),
);
