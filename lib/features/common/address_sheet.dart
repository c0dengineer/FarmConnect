import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';

/// Bottom sheet to add a new delivery address. Returns the saved Address (or null).
Future<Address?> showAddAddressSheet(BuildContext context, WidgetRef ref, AppUser user) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AddAddressSheet(user: user),
  );
}

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet({required this.user});
  final AppUser user;
  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _form = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Home');
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _pin = TextEditingController();
  double? _lat, _lng;
  bool _busy = false;

  Future<void> _locate() async {
    setState(() => _busy = true);
    final pos = await LocationService.current();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
      final a = await LocationService.addressFor(pos.latitude, pos.longitude);
      if (a.isNotEmpty && _line1.text.isEmpty) _line1.text = a;
    } else if (mounted) {
      showMsg(context, 'Location unavailable. You can still type the address.');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final a = Address(
      label: _label.text.trim(),
      line1: _line1.text.trim(),
      city: _city.text.trim(),
      pincode: _pin.text.trim(),
      lat: _lat,
      lng: _lng,
    );
    setState(() => _busy = true);
    try {
      await ref.read(authRepoProvider).saveAddresses(widget.user.uid, [...widget.user.addresses, a]);
      if (mounted) Navigator.pop(context, a);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMsg(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            PrimaryButton(
              label: _lat == null ? 'Use my current location' : 'Location captured',
              icon: Icons.my_location_rounded,
              outlined: true,
              loading: _busy,
              onPressed: _locate,
            ),
            const SizedBox(height: 14),
            AppField(controller: _label, label: 'Label (Home, Work...)', validator: requiredValidator),
            const SizedBox(height: 12),
            AppField(controller: _line1, label: 'Address', maxLines: 2, validator: requiredValidator),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppField(controller: _city, label: 'City', validator: requiredValidator)),
              const SizedBox(width: 12),
              Expanded(child: AppField(controller: _pin, label: 'Pincode', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Save address', loading: _busy, onPressed: _save),
          ]),
        ),
      ),
    );
  }
}
