import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key, this.showBack = false});
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My cart'),
        automaticallyImplyLeading: showBack,
        actions: [if (!cart.isEmpty) TextButton(onPressed: notifier.clear, child: const Text('Clear'))],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add fresh produce from nearby farms.',
              action: showBack ? PrimaryButton(label: 'Browse produce', expand: false, onPressed: () => context.pop()) : null,
            )
          : Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      const Icon(Icons.agriculture_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('From ${cart.farmName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  ...cart.items.values.map((it) {
                    final p = it.product;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Row(children: [
                          NetImage(p.imageUrls.isEmpty ? null : p.imageUrls.first, width: 64, height: 64, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${money(p.effectivePrice)} / ${p.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                              const SizedBox(height: 8),
                              Row(children: [
                                QtyStepper(qty: it.qty, max: p.quantityAvailable, onChanged: (v) => notifier.setQty(p.id, v)),
                                const Spacer(),
                                Text(money(p.effectivePrice * it.qty), style: const TextStyle(fontWeight: FontWeight.w800)),
                              ]),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  }),
                ]),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + (showBack ? MediaQuery.of(context).padding.bottom : 0)),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.muted)),
                    const Spacer(),
                    Text(money(cart.subtotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Proceed to checkout', onPressed: () => context.push('/checkout')),
                ]),
              ),
            ]),
    );
  }
}
