import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit(FarmOrder order, String name) async {
    setState(() => _busy = true);
    try {
      await ref.read(reviewRepoProvider).submit(order: order, rating: _rating, comment: _comment.text, customerName: name);
      if (mounted) {
        showMsg(context, 'Thanks for your review!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMsg(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.orderId)).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your order')),
      body: order == null || user == null
          ? const LoadingView()
          : ListView(padding: const EdgeInsets.all(20), children: [
              Text('How was your order from ${order.farmName}?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(order.items.map((e) => e.name).join(', '), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              RatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v)),
              const SizedBox(height: 16),
              AppField(controller: _comment, label: 'Share more about the freshness and quality (optional)', maxLines: 4),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Submit review', loading: _busy, onPressed: () => _submit(order, user.name)),
            ]),
    );
  }
}
