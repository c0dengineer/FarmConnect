import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/common/address_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _fulfillment = 'delivery';
  String _paymentMethod = 'cod';
  int _addrIndex = 0;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final farm = ref.watch(farmProvider(cart.farmerUid ?? '_')).valueOrNull;

    if (cart.isEmpty || user == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Nothing to check out'));
    }

    final isDelivery = _fulfillment == 'delivery';
    final addresses = user.addresses;
    final addr = (addresses.isNotEmpty && _addrIndex < addresses.length)
        ? addresses[_addrIndex]
        : null;

    double? dist;
    if (farm != null) {
      dist = (isDelivery && addr?.lat != null)
          ? haversineKm(addr!.lat!, addr.lng!, farm.lat, farm.lng)
          : distanceKm(pos, farm.lat, farm.lng);
    }
    final fee = (isDelivery && farm != null && farm.deliveryAvailable)
        ? AppConstants.baseDeliveryFee +
            AppConstants.perKmDeliveryFee * (dist ?? 0)
        : 0.0;
    final total = cart.subtotal + fee;

    String? problem;
    if (farm == null) {
      problem = 'Loading farm details...';
    } else if (isDelivery && !farm.deliveryAvailable) {
      problem = 'This farm does not offer delivery. Choose pickup.';
    } else if (!isDelivery && !farm.pickupAvailable) {
      problem = 'This farm does not offer pickup. Choose delivery.';
    } else if (isDelivery && addr == null) {
      problem = 'Add a delivery address to continue.';
    } else if (isDelivery && dist == null) {
      problem =
          'Choose a delivery location so FarmConnect can calculate the distance and fee.';
    } else if (isDelivery && dist != null && dist > farm.deliveryRadiusKm) {
      problem =
          'You are ${fmtDistance(dist)} away - outside this farm\'s ${farm.deliveryRadiusKm.toInt()} km delivery range.';
    } else if (_paymentMethod == 'upi' && farm.upiId.isEmpty) {
      problem =
          'This farm has not added a UPI ID. Choose cash or contact the farmer.';
    }

    Future<void> place() async {
      final currentFarm = farm;
      final deliveryAddress = addr;
      if (currentFarm == null || (isDelivery && deliveryAddress == null)) {
        return;
      }
      setState(() => _busy = true);
      try {
        final now = DateTime.now();
        final order = FarmOrder(
          id: '',
          customerUid: user.uid,
          customerName: user.name,
          customerPhone: user.phone,
          farmerUid: cart.farmerUid!,
          farmName: cart.farmName!,
          farmPhone: currentFarm.phone,
          items: cart.items.values
              .map((c) => OrderItem(
                    productId: c.product.id,
                    name: c.product.name,
                    unit: c.product.unit,
                    imageUrl: c.product.imageUrls.isEmpty
                        ? null
                        : c.product.imageUrls.first,
                    price: c.product.effectivePrice,
                    qty: c.qty,
                    isUgly: c.product.isUgly,
                  ))
              .toList(),
          subtotal: cart.subtotal,
          deliveryFee: fee,
          total: total,
          distanceKm: dist ?? 0,
          fulfillment: _fulfillment,
          address: isDelivery
              ? deliveryAddress!.full
              : 'Pickup at ${currentFarm.address.isEmpty ? currentFarm.farmName : currentFarm.address}',
          paymentMethod: _paymentMethod,
          paymentUpiId: _paymentMethod == 'upi' ? currentFarm.upiId : '',
          status: OrderStatus.placed,
          note: _note.text.trim(),
          history: [StatusEntry(OrderStatus.placed, now)],
          createdAt: now,
        );
        final id = await ref.read(orderRepoProvider).placeOrder(order);
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        context.go('/customer?tab=3');
        context.push('/order/$id');
      } catch (e) {
        if (mounted) {
          setState(() => _busy = false);
          showMsg(context, e.toString().replaceFirst('Exception: ', ''));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(children: [
        Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                const Text('How would you like it?',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'delivery',
                          label: Text('Delivery'),
                          icon: Icon(Icons.delivery_dining_rounded)),
                      ButtonSegment(
                          value: 'pickup',
                          label: Text('Pickup'),
                          icon: Icon(Icons.storefront_rounded)),
                    ],
                    selected: {_fulfillment},
                    onSelectionChanged: (s) =>
                        setState(() => _fulfillment = s.first),
                    style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.primarySoft,
                        selectedForegroundColor: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 18),
                if (isDelivery) ...[
                  Row(children: [
                    const Expanded(
                        child: Text('Delivery address',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16))),
                    TextButton.icon(
                      onPressed: () async {
                        final a = await showAddAddressSheet(context, ref, user);
                        if (a != null) {
                          setState(() => _addrIndex = user.addresses.length);
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add new'),
                    ),
                  ]),
                  if (addresses.isEmpty)
                    const AppCard(
                        child: Text('No saved addresses yet.',
                            style: TextStyle(color: AppColors.muted)))
                  else
                    ...List.generate(addresses.length, (i) {
                      final a = addresses[i];
                      final on = i == _addrIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _addrIndex = i),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: on ? AppColors.primarySoft : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      on ? AppColors.primary : AppColors.border,
                                  width: on ? 1.6 : 1),
                            ),
                            child: Row(children: [
                              Icon(
                                  on
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color:
                                      on ? AppColors.primary : AppColors.muted),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(a.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text(a.full,
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12.5)),
                                  ])),
                            ]),
                          ),
                        ),
                      );
                    }),
                ] else
                  AppCard(
                      child: Row(children: [
                    const Icon(Icons.storefront_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            farm == null
                                ? '...'
                                : 'Collect from ${farm.farmName}\n${farm.address}',
                            style: const TextStyle(fontSize: 13.5))),
                  ])),
                const SizedBox(height: 18),
                const Text('Payment',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: RadioGroup<String>(
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                    child: Column(children: [
                      RadioListTile<String>(
                        value: 'cod',
                        title: const Text('Cash on delivery / pickup'),
                        secondary: const Icon(Icons.payments_outlined,
                            color: AppColors.primary),
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'upi',
                        enabled: farm?.upiId.isNotEmpty == true,
                        title: const Text('UPI direct to the farm'),
                        subtitle: Text(farm?.upiId.isNotEmpty == true
                            ? farm!.upiId
                            : 'Farmer has not added a UPI ID'),
                        secondary: const Icon(Icons.qr_code_2_rounded,
                            color: AppColors.primary),
                        activeColor: AppColors.primary,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(
                            'UPI transfers go directly to the farm. The farmer confirms payment after checking their bank or UPI app.',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                AppField(
                    controller: _note,
                    label: 'Note for the farmer (optional)',
                    maxLines: 2),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(children: [
                    _row(
                        'Subtotal (${cart.count} items)', money(cart.subtotal)),
                    if (isDelivery) ...[
                      const SizedBox(height: 8),
                      _row('Base delivery fee',
                          money(AppConstants.baseDeliveryFee)),
                      if (dist != null) ...[
                        const SizedBox(height: 6),
                        _row(
                          'Distance (${fmtDistance(dist)} × ${money(AppConstants.perKmDeliveryFee)}/km)',
                          money(AppConstants.perKmDeliveryFee * dist),
                        ),
                      ],
                      const Divider(height: 20),
                      _row('Delivery fee', money(fee)),
                    ] else ...[
                      const SizedBox(height: 8),
                      _row('Delivery fee', 'Free'),
                    ],
                    const Divider(height: 24),
                    _row('Total', money(total), bold: true),
                  ]),
                ),
                if (problem != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(problem,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13))),
              ]),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border))),
          child: PrimaryButton(
              label: 'Place order · ${money(total)}',
              loading: _busy,
              onPressed: problem == null ? place : null),
        ),
      ]),
    );
  }

  Widget _row(String l, String v, {bool bold = false}) => Row(children: [
        Text(l,
            style: TextStyle(
                color: bold ? AppColors.text : AppColors.muted,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        const Spacer(),
        Text(v,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 17 : 14)),
      ]);
}
