import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerOrdersProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My orders'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Active'), Tab(text: 'Past')],
          ),
        ),
        body: async.whenUi((orders) {
          final active = orders.where((o) => OrderStatus.active.contains(o.status)).toList();
          final past = orders.where((o) => !OrderStatus.active.contains(o.status)).toList();
          return TabBarView(children: [
            OrderList(orders: active, empty: 'No active orders'),
            OrderList(orders: past, empty: 'No past orders yet'),
          ]);
        }),
      ),
    );
  }
}

/// Shared list used by customer and farmer order tabs.
class OrderList extends StatelessWidget {
  const OrderList({super.key, required this.orders, required this.empty, this.showCustomer = false});
  final List<FarmOrder> orders;
  final String empty;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, title: empty);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final o = orders[i];
        return AppCard(
          onTap: () => context.push('/order/${o.id}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(showCustomer ? o.customerName : o.farmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              StatusPill(o.status),
            ]),
            const SizedBox(height: 6),
            Text(o.items.map((e) => '${e.qty}× ${e.name}').join(', '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [
              Text(fmtDateTime(o.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const Spacer(),
              Text(money(o.total), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ]),
        );
      },
    );
  }
}
