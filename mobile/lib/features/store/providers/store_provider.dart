import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';

final productsProvider = StreamProvider(
  (ref) => ProductRepository().products(),
);
