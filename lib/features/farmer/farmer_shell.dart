import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/farmer/dashboard_screen.dart';
import 'package:farmconnect/features/farmer/farmer_alerts_screen.dart';
import 'package:farmconnect/features/farmer/farmer_orders_screen.dart';
import 'package:farmconnect/features/farmer/farmer_profile_tab.dart';
import 'package:farmconnect/features/farmer/my_products_screen.dart';

class FarmerShell extends ConsumerStatefulWidget {
  const FarmerShell({super.key});
  @override
  ConsumerState<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends ConsumerState<FarmerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pending = (ref.watch(farmerOrdersProvider).valueOrNull ?? []).where((o) => o.status == OrderStatus.placed).length;
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        DashboardScreen(),
        MyProductsScreen(),
        FarmerOrdersScreen(),
        FarmerAlertsScreen(),
        FarmerProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Products'),
          NavigationDestination(
            icon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.receipt_long_outlined)),
            selectedIcon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.receipt_long_rounded)),
            label: 'Orders',
          ),
          const NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Alerts'),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
