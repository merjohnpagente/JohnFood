import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';

class ReviewSheet extends StatefulWidget {
  final String orderId;
  final String userId;
  final String foodId;
  const ReviewSheet({super.key, required this.orderId, required this.userId, required this.foodId});
  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  double _rating = 5;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: ContentWidth(
        maxWidth: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Rate your meal', style: TextStyle(fontWeight: FontWeight.w700)),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _rating = i.toDouble()),
                    icon: Icon(
                      i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFB300),
                    ),
                  ),
              ],
            ),
            AppTextField(controller: _comment, label: 'Comment (optional)', maxLines: 2),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Submit review',
              loading: _sending,
              onPressed: () async {
                setState(() => _sending = true);
                await ReviewService().submitReview(
                  orderId: widget.orderId,
                  userId: widget.userId,
                  foodId: widget.foodId,
                  rating: _rating,
                  comment: _comment.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
