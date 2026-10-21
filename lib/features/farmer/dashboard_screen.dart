import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final farm = ref.watch(myFarmProvider);
    final orders = ref.watch(farmerOrdersProvider).valueOrNull ?? [];
    final mine = ref.watch(myProductsProvider).valueOrNull ?? [];
    final allProducts = ref.watch(productsProvider).valueOrNull ?? [];

    final now = DateTime.now();
    final delivered = orders.where((o) => o.status == OrderStatus.delivered);
    double sum(bool Function(FarmOrder) f) => delivered.where(f).fold(0.0, (s, o) => s + o.subtotal);
    final today = sum((o) => sameDay(o.createdAt, now));
    final week = sum((o) => now.difference(o.createdAt).inDays < 7);
    final month = sum((o) => now.difference(o.createdAt).inDays < 30);
    final todayOrders = orders.where((o) => sameDay(o.createdAt, now)).length;
    final pending = orders.where((o) => o.status == OrderStatus.placed).length;

    final lowStock = mine.where((p) => p.isAvailable && p.quantityAvailable > 0 && p.quantityAvailable <= 5).toList();
    final aging = mine.where((p) => p.isAvailable && !p.isPreOrder && p.freshness > 0 && p.freshness < 40).toList();

    // Demand insight: which categories sell the most across the marketplace.
    final demand = <String, double>{};
    for (final p in allProducts) {
      demand[p.category] = (demand[p.category] ?? 0) + p.totalSold;
    }
    final trending = demand.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

    Widget stat(String label, String value, IconData icon, {Color color = AppColors.primary}) => Expanded(
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        );

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
        Text('Hello, ${(user?.name ?? '').split(' ').first} 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(farm.valueOrNull?.farmName ?? 'Set up your farm to start selling', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        if (farm.hasValue && farm.value == null)
          AppCard(
            color: AppColors.accentSoft,
            onTap: () => context.push('/farm-edit'),
            child: const Row(children: [
              Icon(Icons.agriculture_rounded, color: AppColors.accent),
              SizedBox(width: 12),
              Expanded(child: Text('Create your farm profile first - it sets your location so customers can find you.', style: TextStyle(fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right_rounded),
            ]),
          ),
        Row(children: [
          stat('Today\'s orders', '$todayOrders', Icons.shopping_bag_outlined),
          const SizedBox(width: 10),
          stat('Pending', '$pending', Icons.hourglass_bottom_rounded, color: AppColors.accent),
        ]),
        const SizedBox(height: 10),
        const SectionHeader('Earnings (delivered orders)'),
        Row(children: [
          stat('Today', money(today), Icons.today_rounded),
          const SizedBox(width: 10),
          stat('7 days', money(week), Icons.date_range_rounded),
          const SizedBox(width: 10),
          stat('30 days', money(month), Icons.calendar_month_rounded),
        ]),
        const SectionHeader('Quick actions'),
        Row(children: [
          Expanded(child: PrimaryButton(label: 'Add product', icon: Icons.add_rounded, onPressed: () => context.push('/product-form'))),
        ]),
        if (trending.isNotEmpty) ...[
          const SectionHeader('Demand insights'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Trending on FarmConnect', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in trending.take(4)) Pill('${e.key} · ${e.value} sold', icon: AppConstants.categoryIcons[e.key]),
              ]),
              const SizedBox(height: 10),
              Text('Consider listing more ${trending.first.key.toLowerCase()} - customers are buying it the most.', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
        ],
        if (aging.isNotEmpty || lowStock.isNotEmpty) ...[
          const SectionHeader('Needs attention'),
          for (final p in aging)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => context.push('/product-form', extra: p),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${p.name} is ${p.freshness}% fresh. Tip: offer a ${suggestedDiscount(p.freshness)}% discount via "Ugly but Fresh" to sell it fast.', style: const TextStyle(fontSize: 13))),
                ]),
              ),
            ),
          for (final p in lowStock)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => context.push('/product-form', extra: p),
                child: Row(children: [
                  const Icon(Icons.inventory_outlined, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${p.name}: only ${formatQuantity(p.quantityAvailable)} ${p.unit} left.', style: const TextStyle(fontSize: 13))),
                ]),
              ),
            ),
        ],
      ]),
    );
  }
}
