import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class FarmerProfileTab extends ConsumerWidget {
  const FarmerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final farm = ref.watch(myFarmProvider).valueOrNull;
    final reviews = ref.watch(farmReviewsProvider(user?.uid ?? '_')).valueOrNull ?? [];

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (farm == null)
          EmptyState(
            icon: Icons.agriculture_outlined,
            title: 'No farm profile yet',
            subtitle: 'Add your farm details and pin your location on the map.',
            action: PrimaryButton(label: 'Create farm profile', expand: false, onPressed: () => context.push('/farm-edit')),
          )
        else ...[
          NetImage(farm.photoUrls.isEmpty ? null : farm.photoUrls.first, height: 150, width: double.infinity, radius: 20),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text(farm.farmName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            if (farm.isVerified) const Pill('Verified', color: AppColors.info, icon: Icons.verified_rounded) else const Pill('Not verified yet', color: AppColors.muted),
          ]),
          const SizedBox(height: 6),
          RatingStars(farm.ratingAvg, count: farm.ratingCount),
          const SizedBox(height: 6),
          Text(farm.address.isEmpty ? 'No address' : farm.address, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Edit farm profile', icon: Icons.edit_outlined, outlined: true, onPressed: () => context.push('/farm-edit')),
        ],
        SectionHeader('Recent reviews (${reviews.length})'),
        if (reviews.isEmpty)
          const Text('No reviews yet.', style: TextStyle(color: AppColors.muted))
        else
          ...reviews.take(4).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), RatingStars(r.rating.toDouble(), size: 14)]),
                    if (r.comment.isNotEmpty) ...[const SizedBox(height: 6), Text(r.comment)],
                  ]),
                ),
              )),
        const SizedBox(height: 16),
        AppCard(child: Row(children: [
          const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ])),
        ])),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Sign out', outlined: true, icon: Icons.logout_rounded, onPressed: () => ref.read(authRepoProvider).signOut()),
      ]),
    );
  }
}
