import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
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
    final locationName = ref.watch(userLocationNameProvider);
    final alerts = ref.watch(followedAlertsProvider).valueOrNull ?? [];
    final farms = ref.watch(farmsProvider).valueOrNull ?? [];
    final orders = ref.watch(customerOrdersProvider).valueOrNull ?? [];
    final first = (user?.name ?? '').split(' ').first;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(userLocationProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.spa_rounded,
                      color: Colors.white, size: 21)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('DIRECT HARVEST',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                    const Text('FarmConnect',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.2)),
                  ])),
              IconButton(
                onPressed: () => context.push('/feed'),
                icon: Badge(
                  isLabelVisible: alerts.isNotEmpty,
                  label: Text('${alerts.length.clamp(0, 9)}'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              InkWell(
                  onTap: () => context.go('/customer?tab=4'),
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(first.isEmpty ? 'F' : first[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)))),
            ]),
            const SizedBox(height: 14),
            InkWell(
                onTap: () async {
                  final picked = await context.push<LatLng>('/location-picker');
                  if (picked == null || !context.mounted) return;
                  final place = await LocationService.addressFor(
                      picked.latitude, picked.longitude);
                  if (!context.mounted) return;
                  ref.read(userLocationProvider.notifier).select(
                        picked.latitude,
                        picked.longitude,
                        place.isEmpty ? 'Pinned location' : place,
                      );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 19),
                      const SizedBox(width: 7),
                      Expanded(
                          child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('DELIVERING TO',
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                locationName?.isNotEmpty == true
                                    ? locationName!
                                    : (pos == null
                                        ? 'Choose your location'
                                        : 'Farms near you'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ])),
                        const Icon(Icons.expand_more_rounded, size: 20),
                      ])),
                      const SizedBox(width: 8),
                      const Pill('100% Direct', icon: Icons.eco_rounded),
                    ]))),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 10),
              AppCard(
                color: AppColors.accentSoft,
                onTap: () => context.push('/feed'),
                child: Row(children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('New from ${alerts.first.farmName}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                        Text(alerts.first.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        Text(alerts.first.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ])),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: .55))),
                    child: const Row(children: [
                      Icon(Icons.search_rounded, color: AppColors.muted),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text('Search fresh produce and farms',
                              style: TextStyle(color: AppColors.muted))),
                      Icon(Icons.tune_rounded, color: AppColors.primary)
                    ]))),
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
                    onTap: () =>
                        context.push('/search?cat=${Uri.encodeComponent(c)}'),
                    child: SizedBox(
                      width: 72,
                      child: Column(children: [
                        Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border)),
                          child: Icon(
                              AppConstants.categoryIcons[c] ??
                                  Icons.shopping_basket_outlined,
                              size: 26,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(c,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
                color: AppColors.primary,
                padding: const EdgeInsets.all(18),
                onTap: () => context.push('/search'),
                child: Row(children: [
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Pill('DIRECT FROM FARM',
                            color: Colors.white,
                            bg: Color(0x3348A66A),
                            icon: Icons.bolt_rounded),
                        SizedBox(height: 9),
                        Text('Fresh from the farm.\nChosen for your table.',
                            style: TextStyle(
                                fontSize: 20,
                                height: 1.18,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 6),
                        Text('Fresh from family farms near you',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                  const SizedBox(width: 8),
                  Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.local_florist_rounded,
                          color: Colors.white, size: 38)),
                ])),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.accentSoft,
              onTap: () => context.push('/ugly'),
              child: Row(children: [
                const Icon(Icons.eco_rounded,
                    color: AppColors.accent, size: 32),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ugly but Fresh',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text(
                            'Imperfect looks, perfect taste. Save money and food waste.',
                            style: TextStyle(fontSize: 12.5)),
                      ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            products.whenUi((all) {
              if (all.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(children: [
                    const EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No produce listed yet',
                        subtitle:
                            'Local growers have not published their first harvest. Explore farms nearby or check back soon.'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                        onPressed: () => context.go('/customer?tab=1'),
                        icon: const Icon(Icons.explore_outlined),
                        label: const Text('Explore nearby farms')),
                  ]),
                );
              }
              // Rule-based recommendations
              final nearby = [...all];
              if (pos != null) {
                nearby.sort((a, b) => distanceKm(pos, a.lat, a.lng)!
                    .compareTo(distanceKm(pos, b.lat, b.lng)!));
              }
              final popular = [
                ...(pos != null ? nearby.take(30).toList() : all)
              ]..sort((a, b) => b.totalSold.compareTo(a.totalSold));
              final freshest = [...all]
                ..sort((a, b) => b.freshness.compareTo(a.freshness));
              final preorders = all.where((p) => p.isPreOrder).toList();
              final boughtIds =
                  orders.expand((o) => o.items.map((i) => i.productId)).toSet();
              final again = all.where((p) => boughtIds.contains(p.id)).toList();
              final followed = user?.followedFarmIds ?? [];
              final fromFollowed =
                  all.where((p) => followed.contains(p.farmerUid)).toList();

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader('Fresh near you',
                        action: 'See all',
                        onAction: () => context.push('/search')),
                    _productRow(popular.take(10).toList(), pos),
                    if (preorders.isNotEmpty) ...[
                      SectionHeader('Reserve an upcoming harvest',
                          action: 'See all',
                          onAction: () => context.push('/search')),
                      _productRow(preorders.take(10).toList(), pos),
                    ],
                    SectionHeader('Freshest right now'),
                    _productRow(freshest.take(10).toList(), pos),
                    if (again.isNotEmpty) ...[
                      SectionHeader('Buy again'),
                      _productRow(again.take(10).toList(), pos)
                    ],
                    if (fromFollowed.isNotEmpty) ...[
                      SectionHeader('From farms you follow'),
                      _productRow(fromFollowed.take(10).toList(), pos)
                    ],
                  ]);
            }),
            if (farms.isNotEmpty) ...[
              SectionHeader('Farms near you'),
              ...(([...farms]..sort((a, b) {
                      if (pos == null) {
                        return b.ratingAvg.compareTo(a.ratingAvg);
                      }
                      return distanceKm(pos, a.lat, a.lng)!
                          .compareTo(distanceKm(pos, b.lat, b.lng)!);
                    }))
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FarmTile(
                          farm: entry.value,
                          distanceKm:
                              distanceKm(pos, entry.value.lat, entry.value.lng),
                          isNearest: pos != null && entry.key == 0,
                        ),
                      ))),
            ],
          ],
        ),
      ),
    );
  }
}
