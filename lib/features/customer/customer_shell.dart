import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/customer/cart_screen.dart';
import 'package:farmconnect/features/customer/explore_screen.dart';
import 'package:farmconnect/features/customer/home_screen.dart';
import 'package:farmconnect/features/customer/orders_screen.dart';
import 'package:farmconnect/features/customer/profile_screen.dart';

class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  late int _index = widget.initialTab.clamp(0, 4).toInt();

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartProvider).count;
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        ExploreScreen(),
        CartScreen(),
        OrdersScreen(),
        ProfileScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explore'),
          NavigationDestination(
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_bag_outlined)),
            selectedIcon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_bag_rounded)),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
