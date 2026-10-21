import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/customer/orders_screen.dart';

class FarmerOrdersScreen extends ConsumerWidget {
  const FarmerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(farmerOrdersProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'New'), Tab(text: 'In progress'), Tab(text: 'Completed')],
          ),
        ),
        body: async.whenUi((orders) {
          final fresh = orders.where((o) => o.status == OrderStatus.placed).toList();
          final going = orders.where((o) => [OrderStatus.accepted, OrderStatus.packed, OrderStatus.outForDelivery].contains(o.status)).toList();
          final done = orders.where((o) => [OrderStatus.delivered, OrderStatus.rejected, OrderStatus.cancelled].contains(o.status)).toList();
          return TabBarView(children: [
            OrderList(orders: fresh, empty: 'No new orders', showCustomer: true),
            OrderList(orders: going, empty: 'Nothing in progress', showCustomer: true),
            OrderList(orders: done, empty: 'No completed orders yet', showCustomer: true),
          ]);
        }),
      ),
    );
  }
}
