import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../data/models/review_model.dart';
import '../providers/review_provider.dart';
import 'star_rating.dart';

/// Opens the review submission form. Pass [existing] to pre-fill it for
/// editing the user's own review; leave it null to write a new one.
Future<void> showReviewFormSheet(BuildContext context, {ReviewModel? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReviewFormSheet(existing: existing),
  );
}

class ReviewFormSheet extends ConsumerStatefulWidget {
  const ReviewFormSheet({super.key, this.existing});
  final ReviewModel? existing;
  @override
  ConsumerState<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<ReviewFormSheet> {
  late int rating = widget.existing?.rating ?? 0;
  late final comment = TextEditingController(text: widget.existing?.comment ?? '');
  bool busy = false;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (rating == 0) {
      showMessage(context, 'Select a star rating first.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .submitReview(rating: rating, comment: comment.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        showMessage(context, 'Thanks for your review!');
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.existing == null ? 'Write a Review' : 'Edit Your Review',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: StarRating(
              rating: rating.toDouble(),
              size: 36,
              onChanged: (value) => setState(() => rating = value),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: comment,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Share your experience (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          JbbButton(label: 'Submit Review', busy: busy, onPressed: submit),
        ],
      ),
    ),
  );
}
