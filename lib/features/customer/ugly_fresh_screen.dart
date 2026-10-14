import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';

class UglyFreshScreen extends ConsumerWidget {
  const UglyFreshScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final products = ref.watch(visibleProductsProvider);
    final orders = ref.watch(customerOrdersProvider).valueOrNull ?? [];
    // Impact: ugly items from delivered orders
    final rescued = orders
        .where((o) => o.status == OrderStatus.delivered)
        .expand((o) => o.items)
        .where((i) => i.isUgly)
        .fold<int>(0, (s, i) => s + i.qty);

    return Scaffold(
      appBar: AppBar(title: const Text('Ugly but Fresh')),
      body: products.whenUi((all) {
        final list = all.where((p) => p.isUgly && p.freshness >= AppConstants.uglyMinFreshness).toList()
          ..sort((a, b) => b.uglyDiscountPercent.compareTo(a.uglyDiscountPercent));
        return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
          AppCard(
            color: AppColors.accentSoft,
            child: Row(children: [
              const Text('🌍', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Rescue produce, save money', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    rescued == 0
                        ? 'These items are just as fresh and tasty - only the shape or size is imperfect.'
                        : 'You have rescued $rescued item${rescued == 1 ? '' : 's'} from going to waste. Thank you!',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(icon: Icons.eco_outlined, title: 'Nothing here right now', subtitle: 'Farmers list imperfect-but-fresh produce here at a discount.'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 246),
              itemCount: list.length,
              itemBuilder: (_, i) => ProductCard(product: list[i], distanceKm: distanceKm(pos, list[i].lat, list[i].lng)),
            ),
        ]);
      }),
    );
  }
}
