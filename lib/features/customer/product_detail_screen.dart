import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.id));
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: async.whenUi((p) {
        if (p == null) return const SafeArea(child: EmptyState(icon: Icons.search_off_rounded, title: 'Product not found'));
        final fav = user?.favoriteProductIds.contains(p.id) ?? false;
        final dist = distanceKm(pos, p.lat, p.lng);
        final reviews = ref.watch(productReviewsProvider(p.id)).valueOrNull ?? [];
        final qty = _qty.clamp(1, p.quantityAvailable < 1 ? 1 : p.quantityAvailable).toInt();
        final canBuy = p.isBuyable;

        return Column(children: [
          Expanded(
            child: CustomScrollView(slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: () => context.pop())),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: fav ? AppColors.danger : AppColors.text),
                        onPressed: user == null ? null : () => ref.read(authRepoProvider).toggleFavorite(user.uid, p.id, !fav),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(children: [
                    p.imageUrls.isEmpty
                        ? const NetImage(null, width: double.infinity, height: 300)
                        : PageView(
                            onPageChanged: (i) => setState(() => _page = i),
                            children: p.imageUrls.map((u) => NetImage(u, width: double.infinity, height: 300)).toList(),
                          ),
                    if (p.imageUrls.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (var i = 0; i < p.imageUrls.length; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(color: i == _page ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(6)),
                            ),
                        ]),
                      ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      Pill(p.category, color: AppColors.muted),
                      if (p.isOrganic) const Pill('Organic', icon: Icons.spa_rounded),
                      if (p.isUgly) const Pill('Ugly but Fresh', color: AppColors.accent, icon: Icons.recycling_rounded),
                      if (p.isPreOrder) const Pill('Pre-order', color: AppColors.info),
                    ]),
                    const SizedBox(height: 12),
                    Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: money(p.effectivePrice), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        if (p.isUgly && p.uglyDiscountPercent > 0)
                          TextSpan(text: '  ${money(p.price)}', style: const TextStyle(color: AppColors.muted, decoration: TextDecoration.lineThrough)),
                        TextSpan(text: '  per ${p.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ])),
                      const Spacer(),
                      RatingStars(p.ratingAvg, count: p.ratingCount),
                    ]),
                    const SizedBox(height: 18),
                    // Freshness card
                    AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.eco_rounded, color: freshnessColor(p.freshness)),
                          const SizedBox(width: 8),
                          Text('Freshness score', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('${p.freshness}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: freshnessColor(p.freshness))),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: p.freshness / 100, minHeight: 8, backgroundColor: AppColors.bg, color: freshnessColor(p.freshness)),
                        ),
                        const SizedBox(height: 10),
                        Text('${freshnessLabel(p.freshness)} · ${harvestedAgo(p.harvestDate)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        if (p.isUgly && p.uglyReason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Why "ugly"? ${p.uglyReason}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Farm card
                    AppCard(
                      onTap: () => context.push('/farm/${p.farmerUid}'),
                      child: Row(children: [
                        const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.agriculture_rounded, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.farmName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(dist == null ? 'Distance unavailable' : '${fmtDistance(dist)} from you · ${(dist * 0.12).toStringAsFixed(1)} kg CO₂ saved vs. 100 km supply',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ]),
                    ),
                    if (p.description.isNotEmpty) ...[
                      const SectionHeader('About this produce'),
                      Text(p.description, style: const TextStyle(height: 1.5)),
                    ],
                    SectionHeader('Reviews (${reviews.length})'),
                    if (reviews.isEmpty)
                      const Text('No reviews yet. Be the first after your order!', style: TextStyle(color: AppColors.muted))
                    else
                      ...reviews.take(5).map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  RatingStars(r.rating.toDouble(), size: 14),
                                ]),
                                if (r.comment.isNotEmpty) ...[const SizedBox(height: 6), Text(r.comment)],
                                const SizedBox(height: 6),
                                Text(fmtDate(r.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                              ]),
                            ),
                          )),
                  ]),
                ),
              ),
            ]),
          ),
          // Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              if (canBuy) QtyStepper(qty: qty, max: p.quantityAvailable, onChanged: (v) => setState(() => _qty = v.clamp(1, p.quantityAvailable).toInt())),
              if (canBuy) const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: canBuy ? 'Add to cart · ${money(p.effectivePrice * qty)}' : 'Currently unavailable',
                  icon: Icons.add_shopping_cart_rounded,
                  onPressed: !canBuy
                      ? null
                      : () async {
                          final notifier = ref.read(cartProvider.notifier);
                          if (notifier.conflicts(p)) {
                            final ok = await confirmDialog(context, 'Start a new cart?', 'Your cart has items from another farm. Replace them with this item?', confirm: 'Replace');
                            if (!ok) return;
                          }
                          notifier.add(p, qty: qty);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${p.name} added to cart'),
                              action: SnackBarAction(label: 'VIEW CART', textColor: AppColors.accent, onPressed: () => context.push('/cart')),
                            ));
                          }
                        },
                ),
              ),
            ]),
          ),
        ]);
      }),
    );
  }
}
