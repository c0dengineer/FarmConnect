import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/admin/admin_screen.dart';
import 'package:farmconnect/features/auth/login_screen.dart';
import 'package:farmconnect/features/auth/signup_screen.dart';
import 'package:farmconnect/features/common/location_picker_screen.dart';
import 'package:farmconnect/features/common/order_detail_screen.dart';
import 'package:farmconnect/features/common/splash_screen.dart';
import 'package:farmconnect/features/customer/alerts_feed_screen.dart';
import 'package:farmconnect/features/customer/cart_screen.dart';
import 'package:farmconnect/features/customer/checkout_screen.dart';
import 'package:farmconnect/features/customer/customer_shell.dart';
import 'package:farmconnect/features/customer/farm_detail_screen.dart';
import 'package:farmconnect/features/customer/favorites_screen.dart';
import 'package:farmconnect/features/customer/product_detail_screen.dart';
import 'package:farmconnect/features/customer/review_screen.dart';
import 'package:farmconnect/features/customer/search_screen.dart';
import 'package:farmconnect/features/customer/ugly_fresh_screen.dart';
import 'package:farmconnect/features/farmer/farm_form_screen.dart';
import 'package:farmconnect/features/farmer/farmer_shell.dart';
import 'package:farmconnect/features/farmer/product_form_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(currentUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);
      final loc = state.matchedLocation;
      const authPages = ['/login', '/signup'];

      if (auth.isLoading) return loc == '/splash' ? null : '/splash';
      if (auth.valueOrNull == null) return authPages.contains(loc) ? null : '/login';

      final user = userAsync.valueOrNull;
      if (userAsync.isLoading || user == null) return loc == '/splash' ? null : '/splash';
      if (user.isBlocked) return loc == '/blocked' ? null : '/blocked';

      final home = '/${user.role}';
      if (loc == '/splash' || loc == '/blocked' || authPages.contains(loc)) return home;
      if (user.role == Roles.customer && (loc.startsWith('/farmer') || loc.startsWith('/admin'))) return home;
      if (user.role == Roles.farmer && (loc.startsWith('/customer') || loc.startsWith('/admin'))) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/blocked', builder: (_, __) => const SplashScreen(blocked: true)),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/customer',
        builder: (_, s) {
          final tab = int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0;
          return CustomerShell(key: ValueKey(tab), initialTab: tab);
        },
      ),
      GoRoute(path: '/farmer', builder: (_, __) => const FarmerShell()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(
        path: '/search',
        builder: (_, s) => SearchScreen(
          initialCategory: s.uri.queryParameters['cat'],
          uglyOnly: s.uri.queryParameters['ugly'] == '1',
        ),
      ),
      GoRoute(path: '/ugly', builder: (_, __) => const UglyFreshScreen()),
      GoRoute(path: '/product/:id', builder: (_, s) => ProductDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/farm/:id', builder: (_, s) => FarmDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen(showBack: true)),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/order/:id', builder: (_, s) => OrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/review/:orderId', builder: (_, s) => ReviewScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/feed', builder: (_, __) => const AlertsFeedScreen()),
      GoRoute(path: '/farm-edit', builder: (_, __) => const FarmFormScreen()),
      GoRoute(path: '/product-form', builder: (_, s) => ProductFormScreen(product: s.extra as Product?)),
      GoRoute(path: '/location-picker', builder: (_, s) => LocationPickerScreen(initial: s.extra as LatLng?)),
    ],
  );
});
