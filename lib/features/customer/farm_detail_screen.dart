import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class FarmDetailScreen extends ConsumerWidget {
  const FarmDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider(id));
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final products = (ref.watch(visibleProductsProvider).valueOrNull ?? []).where((p) => p.farmerUid == id).toList();
    final reviews = ref.watch(farmReviewsProvider(id)).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Farm')),
      body: farmAsync.whenUi((f) {
        if (f == null) return const EmptyState(icon: Icons.agriculture_outlined, title: 'Farm not found');
        final following = user?.followedFarmIds.contains(f.id) ?? false;
        final dist = distanceKm(pos, f.lat, f.lng);
        return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), children: [
          NetImage(f.photoUrls.isEmpty ? null : f.photoUrls.first, height: 180, width: double.infinity, radius: 20),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text(f.farmName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            if (f.isVerified) const Pill('Verified', color: AppColors.info, icon: Icons.verified_rounded),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            RatingStars(f.ratingAvg, count: f.ratingCount),
            const SizedBox(width: 12),
            Text(dist == null ? f.farmingType : '${fmtDistance(dist)} away · ${f.farmingType}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          if (user != null && user.role == Roles.customer)
            PrimaryButton(
              label: following ? 'Following · alerts on' : 'Follow for harvest alerts',
              icon: following ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              outlined: following,
              onPressed: () => ref.read(authRepoProvider).toggleFollow(user.uid, f.id, !following),
            ),
          if (f.description.isNotEmpty) ...[const SizedBox(height: 16), Text(f.description, style: const TextStyle(height: 1.5))],
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              _info(Icons.place_outlined, f.address.isEmpty ? 'Address not provided' : f.address),
              const SizedBox(height: 10),
              _info(Icons.delivery_dining_outlined, f.deliveryAvailable ? 'Delivery within ${f.deliveryRadiusKm.toInt()} km' : 'No delivery'),
              const SizedBox(height: 10),
              _info(Icons.storefront_outlined, f.pickupAvailable ? 'Pickup available' : 'No pickup'),
            ]),
          ),
          SectionHeader('Fresh from this farm (${products.length})'),
          if (products.isEmpty)
            const Text('No produce listed right now.', style: TextStyle(color: AppColors.muted))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 246),
              itemCount: products.length,
              itemBuilder: (_, i) => ProductCard(product: products[i], distanceKm: dist),
            ),
          SectionHeader('Reviews (${reviews.length})'),
          if (reviews.isEmpty)
            const Text('No reviews yet.', style: TextStyle(color: AppColors.muted))
          else
            ...reviews.take(5).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), RatingStars(r.rating.toDouble(), size: 14)]),
                      if (r.comment.isNotEmpty) ...[const SizedBox(height: 6), Text(r.comment)],
                    ]),
                  ),
                )),
        ]);
      }),
    );
  }

  Widget _info(IconData i, String t) => Row(children: [
        Icon(i, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5))),
      ]);
}
