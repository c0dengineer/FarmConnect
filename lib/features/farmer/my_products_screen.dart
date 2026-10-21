import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class MyProductsScreen extends ConsumerWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProductsProvider);
    final farm = ref.watch(myFarmProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('My products')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          if (farm == null) {
            showMsg(context, 'Create your farm profile first.');
            context.push('/farm-edit');
          } else {
            context.push('/product-form');
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      body: async.whenUi((list) {
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products yet', subtitle: 'Tap "Add product" to list your first harvest.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final p = list[i];
            final soldOut = p.quantityAvailable <= 0;
            return AppCard(
              onTap: () => context.push('/product-form', extra: p),
              child: Column(children: [
                Row(children: [
                  NetImage(p.imageUrls.isEmpty ? null : p.imageUrls.first, width: 64, height: 64, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${money(p.effectivePrice)} / ${p.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Pill(soldOut ? 'Out of stock' : '${formatQuantity(p.quantityAvailable)} ${p.unit} left', color: soldOut ? AppColors.danger : AppColors.primary),
                        Pill('${p.freshness}% fresh', color: freshnessColor(p.freshness)),
                        if (p.isUgly) const Pill('Ugly', color: AppColors.accent),
                      ]),
                    ]),
                  ),
                ]),
                const Divider(height: 22),
                Row(children: [
                  const Text('Visible to customers', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const Spacer(),
                  Switch(value: p.isAvailable, activeThumbColor: AppColors.primary, onChanged: (v) => ref.read(productRepoProvider).setAvailable(p.id, v)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () async {
                      final ok = await confirmDialog(context, 'Delete product?', 'This will permanently remove ${p.name}.', confirm: 'Delete', danger: true);
                      if (ok) await ref.read(productRepoProvider).delete(p.id);
                    },
                  ),
                ]),
              ]),
            );
          },
        );
      }),
    );
  }
}
