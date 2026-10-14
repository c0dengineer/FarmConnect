import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _productRow(List<Product> list, Position? pos) {
    return SizedBox(
      height: 246,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ProductCard(
          product: list[i],
          width: 170,
          distanceKm: distanceKm(pos, list[i].lat, list[i].lng),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final products = ref.watch(visibleProductsProvider);
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final farms = ref.watch(farmsProvider).valueOrNull ?? [];
    final orders = ref.watch(customerOrdersProvider).valueOrNull ?? [];
    final first = (user?.name ?? '').split(' ').first;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(userLocationProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(first.isEmpty ? 'Hello 👋' : 'Hello, $first 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(pos == null ? Icons.location_off_outlined : Icons.location_on_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(pos == null ? 'Location off - distances hidden' : 'Showing farms near you',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ]),
                ]),
              ),
              IconButton.filledTonal(
                onPressed: () => context.push('/feed'),
                style: IconButton.styleFrom(backgroundColor: AppColors.primarySoft, foregroundColor: AppColors.primary),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ]),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: const Row(children: [
                  Icon(Icons.search_rounded, color: AppColors.muted),
                  SizedBox(width: 10),
                  Text('Search vegetables, fruits, dairy...', style: TextStyle(color: AppColors.muted)),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = AppConstants.categories[i];
                  return GestureDetector(
                    onTap: () => context.push('/search?cat=${Uri.encodeComponent(c)}'),
                    child: SizedBox(
                      width: 72,
                      child: Column(children: [
                        Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
                          child: Text(AppConstants.categoryEmoji[c] ?? '🧺', style: const TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(height: 6),
                        Text(c, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              color: AppColors.accentSoft,
              onTap: () => context.push('/ugly'),
              child: Row(children: [
                const Text('🥕', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ugly but Fresh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Imperfect looks, perfect taste. Save money and food waste.', style: TextStyle(fontSize: 12.5)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            products.whenUi((all) {
              if (all.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(icon: Icons.storefront_outlined, title: 'No produce listed yet', subtitle: 'Check back soon - farmers add fresh harvests every day.'),
                );
              }
              // Rule-based recommendations
              final nearby = [...all];
              if (pos != null) {
                nearby.sort((a, b) => distanceKm(pos, a.lat, a.lng)!.compareTo(distanceKm(pos, b.lat, b.lng)!));
              }
              final popular = [...(pos != null ? nearby.take(30).toList() : all)]..sort((a, b) => b.totalSold.compareTo(a.totalSold));
              final freshest = [...all]..sort((a, b) => b.freshness.compareTo(a.freshness));
              final boughtIds = orders.expand((o) => o.items.map((i) => i.productId)).toSet();
              final again = all.where((p) => boughtIds.contains(p.id)).toList();
              final followed = user?.followedFarmIds ?? [];
              final fromFollowed = all.where((p) => followed.contains(p.farmerUid)).toList();

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionHeader('Popular near you', action: 'See all', onAction: () => context.push('/search')),
                _productRow(popular.take(10).toList(), pos),
                SectionHeader('Freshest right now'),
                _productRow(freshest.take(10).toList(), pos),
                if (again.isNotEmpty) ...[SectionHeader('Buy again'), _productRow(again.take(10).toList(), pos)],
                if (fromFollowed.isNotEmpty) ...[SectionHeader('From farms you follow'), _productRow(fromFollowed.take(10).toList(), pos)],
              ]);
            }),
            if (farms.isNotEmpty) ...[
              SectionHeader('Farms near you'),
              ...(([...farms]..sort((a, b) {
                    if (pos == null) return b.ratingAvg.compareTo(a.ratingAvg);
                    return distanceKm(pos, a.lat, a.lng)!.compareTo(distanceKm(pos, b.lat, b.lng)!);
                  }))
                  .take(5)
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FarmTile(farm: f, distanceKm: distanceKm(pos, f.lat, f.lng)),
                      ))),
            ],
          ],
        ),
      ),
    );
  }
}
