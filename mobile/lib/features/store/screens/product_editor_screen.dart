import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/store_provider.dart';

class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.product});
  final Map<String, dynamic>? product;
  @override
  ConsumerState<ProductEditorScreen> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditorScreen> {
  final form = GlobalKey<FormState>();
  late final id =
      widget.product?['id'] as String? ??
      FirebaseFirestore.instance.collection('products').doc().id;
  late final name = TextEditingController(text: widget.product?['name']);
  late final description = TextEditingController(
    text: widget.product?['description'],
  );
  late final price = TextEditingController(
    text: widget.product?['price'] != null
        ? (widget.product!['price'] / 100).toString()
        : '',
  );
  late String? imageUrl = widget.product?['imageUrl'];
  late bool isActive = widget.product?['isActive'] ?? true;
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => busy = true);
    try {
      final url = await ref
          .read(productRepositoryProvider)
          .uploadImage(id, File(image.path));
      if (mounted) setState(() => imageUrl = url);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final cents = (double.parse(price.text) * 100).round();
    try {
      await ref.read(productRepositoryProvider).save(id, {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'price': cents,
        'priceLabel': '\$${(cents / 100).toStringAsFixed(2)}',
        'imageUrl': imageUrl ?? '',
        'isActive': isActive,
        'sortOrder': widget.product?['sortOrder'] ?? 0,
        'createdAt': widget.product?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${name.text}" from the store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await ref.read(productRepositoryProvider).delete(id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      actions: [
        if (widget.product != null)
          IconButton(
            onPressed: busy ? null : delete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: busy ? null : pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    height: 140,
                    color: Colors.white10,
                    child: (imageUrl ?? '').isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Product name'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price in USD'),
              validator: (v) =>
                  double.tryParse(v ?? '') != null && double.parse(v!) > 0
                  ? null
                  : 'Enter a valid price',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible in the store)'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 16),
            JbbButton(label: 'Save Product', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}
