import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmconnect/core/services/location_service.dart';
import 'package:farmconnect/models/app_user.dart';
import 'package:farmconnect/models/farm.dart';
import 'package:farmconnect/models/harvest_alert.dart';
import 'package:farmconnect/models/order.dart';
import 'package:farmconnect/models/product.dart';
import 'package:farmconnect/models/review.dart';
import 'package:farmconnect/repositories/alert_repo.dart';
import 'package:farmconnect/repositories/auth_repo.dart';
import 'package:farmconnect/repositories/farm_repo.dart';
import 'package:farmconnect/repositories/order_repo.dart';
import 'package:farmconnect/repositories/product_repo.dart';
import 'package:farmconnect/repositories/review_repo.dart';

// ---- Repositories ----
final authRepoProvider = Provider((ref) => AuthRepo());
final farmRepoProvider = Provider((ref) => FarmRepo());
final productRepoProvider = Provider((ref) => ProductRepo());
final orderRepoProvider = Provider((ref) => OrderRepo());
final reviewRepoProvider = Provider((ref) => ReviewRepo());
final alertRepoProvider = Provider((ref) => AlertRepo());

// ---- Auth / user ----
final authStateProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepoProvider).userStream(uid);
});

// ---- Location ----
final userLocationNameProvider = StateProvider<String?>((ref) => null);

class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  UserLocationNotifier(this._ref) : super(const AsyncLoading()) {
    refresh();
  }

  final Ref _ref;
  int _generation = 0;

  Future<void> refresh() async {
    final request = ++_generation;
    state = const AsyncLoading();
    try {
      final position = await LocationService.current();
      if (request != _generation) return;
      if (position == null) {
        state = const AsyncData(null);
        return;
      }
      final name = await LocationService.addressFor(
          position.latitude, position.longitude);
      if (request != _generation) return;
      _ref.read(userLocationNameProvider.notifier).state =
          name.isEmpty ? null : name;
      state = AsyncData(position);
    } catch (error, stack) {
      if (request != _generation) return;
      state = AsyncError(error, stack);
    }
  }

  void select(double latitude, double longitude, String placeName) {
    _generation++;
    _ref.read(userLocationNameProvider.notifier).state = placeName;
    state = AsyncData(Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ));
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>(
  (ref) => UserLocationNotifier(ref),
);

// ---- Products / farms ----
final productsProvider = StreamProvider<List<Product>>(
    (ref) => ref.watch(productRepoProvider).watchAvailable());

/// Only products a customer can actually buy right now.
final visibleProductsProvider = Provider<AsyncValue<List<Product>>>(
  (ref) => ref
      .watch(productsProvider)
      .whenData((l) => l.where((p) => p.isBuyable).toList()),
);

final allProductsAdminProvider = StreamProvider<List<Product>>(
    (ref) => ref.watch(productRepoProvider).watchAll());

final farmsProvider = StreamProvider<List<Farm>>(
    (ref) => ref.watch(farmRepoProvider).watchFarms());

final farmProvider = StreamProvider.family.autoDispose<Farm?, String>(
    (ref, id) => ref.watch(farmRepoProvider).watchFarm(id));

final productProvider = StreamProvider.family.autoDispose<Product?, String>(
    (ref, id) => ref.watch(productRepoProvider).watchById(id));

final myFarmProvider = StreamProvider<Farm?>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(farmRepoProvider).watchFarm(uid);
});

final myProductsProvider = StreamProvider<List<Product>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(productRepoProvider).watchByFarmer(uid);
});

// ---- Orders ----
final customerOrdersProvider = StreamProvider<List<FarmOrder>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(orderRepoProvider).watchForCustomer(uid);
});

final farmerOrdersProvider = StreamProvider<List<FarmOrder>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(orderRepoProvider).watchForFarmer(uid);
});

final orderProvider = StreamProvider.family.autoDispose<FarmOrder?, String>(
    (ref, id) => ref.watch(orderRepoProvider).watchById(id));

final recentOrdersAdminProvider = StreamProvider<List<FarmOrder>>(
    (ref) => ref.watch(orderRepoProvider).watchRecent());

// ---- Reviews / alerts ----
final productReviewsProvider = StreamProvider.family
    .autoDispose<List<Review>, String>(
        (ref, id) => ref.watch(reviewRepoProvider).watchForProduct(id));

final farmReviewsProvider = StreamProvider.family
    .autoDispose<List<Review>, String>(
        (ref, id) => ref.watch(reviewRepoProvider).watchForFarm(id));

final myAlertsProvider = StreamProvider<List<HarvestAlert>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(alertRepoProvider).watchByFarmer(uid);
});

final followedAlertsProvider = StreamProvider<List<HarvestAlert>>((ref) {
  final ids = ref.watch(currentUserProvider).valueOrNull?.followedFarmIds ?? [];
  return ref.watch(alertRepoProvider).watchForFarms(ids);
});

final allUsersAdminProvider = StreamProvider<List<AppUser>>(
    (ref) => ref.watch(authRepoProvider).watchAllUsers());

// ---- Cart (kept in memory; one farmer per cart) ----
class CartItem {
  final Product product;
  final double qty;
  const CartItem(this.product, this.qty);
}

class CartState {
  final String? farmerUid, farmName;
  final Map<String, CartItem> items;
  const CartState({this.farmerUid, this.farmName, this.items = const {}});

  int get count => items.length;
  double get subtotal =>
      items.values.fold(0.0, (s, e) => s + e.product.effectivePrice * e.qty);
  bool get isEmpty => items.isEmpty;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  bool conflicts(Product p) =>
      state.items.isNotEmpty && state.farmerUid != p.farmerUid;

  void add(Product p, {double qty = 1}) {
    if (conflicts(p)) clear();
    final items = Map<String, CartItem>.from(state.items);
    final current = items[p.id]?.qty ?? 0;
    final next = (current + qty).clamp(0.001, p.quantityAvailable).toDouble();
    items[p.id] = CartItem(p, next);
    state =
        CartState(farmerUid: p.farmerUid, farmName: p.farmName, items: items);
  }

  void setQty(String id, double qty) {
    final item = state.items[id];
    if (item == null) return;
    if (qty <= 0) return remove(id);
    final items = Map<String, CartItem>.from(state.items);
    items[id] = CartItem(
      item.product,
      qty.clamp(0.001, item.product.quantityAvailable).toDouble(),
    );
    state = CartState(
        farmerUid: state.farmerUid, farmName: state.farmName, items: items);
  }

  void remove(String id) {
    final items = Map<String, CartItem>.from(state.items)..remove(id);
    state = items.isEmpty
        ? const CartState()
        : CartState(
            farmerUid: state.farmerUid, farmName: state.farmName, items: items);
  }

  void clear() => state = const CartState();
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
