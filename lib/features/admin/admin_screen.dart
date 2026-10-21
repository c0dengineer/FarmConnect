import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/customer/orders_screen.dart';

/// Minimal admin panel. To make an account an admin, set its `role` to "admin" in the Firestore console.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin panel'),
          actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => ref.read(authRepoProvider).signOut())],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Overview'), Tab(text: 'Farmers'), Tab(text: 'Products'), Tab(text: 'Users')],
          ),
        ),
        body: const TabBarView(children: [_Overview(), _Farmers(), _Products(), _Users()]),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersAdminProvider).valueOrNull ?? [];
    final products = ref.watch(allProductsAdminProvider).valueOrNull ?? [];
    final farms = ref.watch(farmsProvider).valueOrNull ?? [];
    final orders = ref.watch(recentOrdersAdminProvider).valueOrNull ?? [];

    Widget stat(String l, String v, IconData i) => Expanded(
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(l, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        );

    final top = [...products]..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [stat('Users', '${users.length}', Icons.people_outline_rounded), const SizedBox(width: 10), stat('Farms', '${farms.length}', Icons.agriculture_outlined)]),
      const SizedBox(height: 10),
      Row(children: [stat('Products', '${products.length}', Icons.inventory_2_outlined), const SizedBox(width: 10), stat('Recent orders', '${orders.length}', Icons.receipt_long_outlined)]),
      const SectionHeader('Top products'),
      for (final p in top.take(5))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(child: Row(children: [
            Expanded(child: Text('${p.name} · ${p.farmName}', maxLines: 1, overflow: TextOverflow.ellipsis)),
            Pill('${p.totalSold} sold'),
          ])),
        ),
      const SectionHeader('Latest orders'),
      SizedBox(height: 420, child: OrderList(orders: orders.take(10).toList(), empty: 'No orders yet', showCustomer: true)),
    ]);
  }
}

class _Farmers extends ConsumerWidget {
  const _Farmers();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(farmsProvider).whenUi((farms) {
      if (farms.isEmpty) return const EmptyState(icon: Icons.agriculture_outlined, title: 'No farms yet');
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: farms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final f = farms[i];
          return AppCard(
            onTap: () => context.push('/farm/${f.id}'),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.farmName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(f.address.isEmpty ? f.ownerName : f.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ])),
              const Text('Verified', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Switch(value: f.isVerified, activeColor: AppColors.primary, onChanged: (v) => ref.read(farmRepoProvider).setVerified(f.id, v)),
            ]),
          );
        },
      );
    });
  }
}

class _Products extends ConsumerWidget {
  const _Products();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(allProductsAdminProvider).whenUi((list) {
      if (list.isEmpty) return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products yet');
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = list[i];
          return AppCard(
            child: Row(children: [
              NetImage(p.imageUrls.isEmpty ? null : p.imageUrls.first, width: 48, height: 48, radius: 10),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${p.farmName} · ${money(p.price)}/${p.unit}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ])),
              Switch(value: p.isAvailable, activeColor: AppColors.primary, onChanged: (v) => ref.read(productRepoProvider).setAvailable(p.id, v)),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                onPressed: () async {
                  if (await confirmDialog(context, 'Remove product?', 'Remove ${p.name} from the marketplace?', confirm: 'Remove', danger: true)) {
                    await ref.read(productRepoProvider).delete(p.id);
                  }
                },
              ),
            ]),
          );
        },
      );
    });
  }
}

class _Users extends ConsumerWidget {
  const _Users();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    return ref.watch(allUsersAdminProvider).whenUi((users) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final u = users[i];
            return AppCard(
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${u.email} · ${u.role}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ])),
                if (u.uid != me?.uid)
                  TextButton(
                    onPressed: () => ref.read(authRepoProvider).setBlocked(u.uid, !u.isBlocked),
                    child: Text(u.isBlocked ? 'Unblock' : 'Block', style: TextStyle(color: u.isBlocked ? AppColors.primary : AppColors.danger)),
                  ),
              ]),
            );
          },
        ));
  }
}
