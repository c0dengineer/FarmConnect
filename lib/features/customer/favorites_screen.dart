import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final all = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: all.whenUi((list) {
        final favs = list.where((p) => user?.favoriteProductIds.contains(p.id) ?? false).toList();
        if (favs.isEmpty) {
          return const EmptyState(icon: Icons.favorite_border_rounded, title: 'No favourites yet', subtitle: 'Tap the heart on any product to save it here.');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 246),
          itemCount: favs.length,
          itemBuilder: (_, i) => ProductCard(product: favs[i], distanceKm: distanceKm(pos, favs[i].lat, favs[i].lng)),
        );
      }),
    );
  }
}
