import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmconnect/all.dart';

class FarmFormScreen extends ConsumerStatefulWidget {
  const FarmFormScreen({super.key});
  @override
  ConsumerState<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends ConsumerState<FarmFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _upi = TextEditingController();
  final _radius = TextEditingController(text: '15');
  String _type = 'traditional';
  bool _delivery = true,
      _pickup = true,
      _busy = false,
      _loaded = false,
      _isNew = true;
  LatLng? _loc;
  List<String> _urls = [];
  List<XFile> _files = [];

  @override
  void dispose() {
    for (final c in [_name, _desc, _phone, _address, _radius, _upi]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Farm? f, AppUser? u) {
    if (_loaded) return;
    _loaded = true;
    if (f == null) {
      _phone.text = u?.phone ?? '';
      return;
    }
    _isNew = false;
    _name.text = f.farmName;
    _desc.text = f.description;
    _phone.text = f.phone;
    _address.text = f.address;
    _upi.text = f.upiId;
    _radius.text = f.deliveryRadiusKm.toInt().toString();
    _type = f.farmingType;
    _delivery = f.deliveryAvailable;
    _pickup = f.pickupAvailable;
    _loc = LatLng(f.lat, f.lng);
    _urls = [...f.photoUrls];
  }

  Future<void> _pickLocation() async {
    final res = await context.push<LatLng>('/location-picker', extra: _loc);
    if (res == null) return;
    setState(() => _loc = res);
    if (_address.text.trim().isEmpty) {
      final a = await LocationService.addressFor(res.latitude, res.longitude);
      if (mounted && a.isNotEmpty) setState(() => _address.text = a);
    }
  }

  Future<void> _save(AppUser user) async {
    if (!_form.currentState!.validate()) return;
    if (_loc == null) {
      return showMsg(context, 'Pick your farm location on the map.');
    }
    if (_files.isNotEmpty && !StorageService.isConfigured) {
      return showMsg(context,
          'Photo uploads need Cloudinary setup. See CLOUDINARY_SETUP.md, then restart with the cloud name and unsigned upload preset.');
    }
    setState(() => _busy = true);
    try {
      final uploaded = await StorageService.upload(_files, 'farms/${user.uid}');
      final farm = Farm(
        id: user.uid,
        farmName: _name.text.trim(),
        ownerName: user.name,
        description: _desc.text.trim(),
        farmingType: _type,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        upiId: _upi.text.trim(),
        photoUrls: StorageService.mergeImageUrls(_urls, uploaded),
        lat: _loc!.latitude,
        lng: _loc!.longitude,
        deliveryRadiusKm: double.tryParse(_radius.text) ?? 15,
        deliveryAvailable: _delivery,
        pickupAvailable: _pickup,
        createdAt: DateTime.now(),
      );
      await ref.read(farmRepoProvider).saveFarm(farm, isNew: _isNew);
      if (mounted) {
        showMsg(context, 'Farm profile saved');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMsg(context, 'Could not save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final farmAsync = ref.watch(myFarmProvider);
    if (user == null || farmAsync.isLoading) {
      return const Scaffold(body: LoadingView());
    }
    _load(farmAsync.valueOrNull, user);

    return Scaffold(
      appBar: AppBar(
          title: Text(_isNew ? 'Create farm profile' : 'Edit farm profile')),
      body: Form(
        key: _form,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              const Text('Farm photos',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              if (!StorageService.isConfigured) ...[
                const SizedBox(height: 10),
                AppCard(
                  color: AppColors.accentSoft,
                  child: Row(children: [
                    const Icon(Icons.cloud_off_outlined,
                        color: AppColors.accent),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: Text(
                            'Photo upload is not configured yet. Set your Cloudinary cloud name and unsigned preset, then restart the app. See CLOUDINARY_SETUP.md.',
                            style: TextStyle(fontSize: 12.5))),
                  ]),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  GestureDetector(
                    onTap: () async {
                      final room = 3 - _urls.length - _files.length;
                      if (room <= 0) {
                        return showMsg(context, 'Maximum 3 photos.');
                      }
                      final f = await StorageService.pick(max: room);
                      if (f.isNotEmpty) {
                        setState(() => _files = [..._files, ...f]);
                      }
                    },
                    child: Container(
                      width: 84,
                      decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4))),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.primary),
                    ),
                  ),
                  for (var i = 0; i < _urls.length; i++)
                    _thumb(
                        NetImage(_urls[i], width: 84, height: 84, radius: 14),
                        () => setState(() => _urls.removeAt(i))),
                  for (var i = 0; i < _files.length; i++)
                    _thumb(
                        FutureBuilder<List<int>>(
                            future: _files[i].readAsBytes(),
                            builder: (context, snapshot) => ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: snapshot.hasData
                                    ? Image.memory(
                                        Uint8List.fromList(snapshot.data!),
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover)
                                    : const SizedBox(
                                        width: 84,
                                        height: 84,
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))))),
                        () => setState(() => _files.removeAt(i))),
                ]),
              ),
              const SizedBox(height: 20),
              AppField(
                  controller: _name,
                  label: 'Farm name',
                  validator: requiredValidator),
              const SizedBox(height: 14),
              AppField(
                  controller: _desc, label: 'About your farm', maxLines: 3),
              const SizedBox(height: 14),
              const Text('Farming type',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final t in ['organic', 'traditional', 'mixed'])
                  ChoiceChip(
                    label: Text(t[0].toUpperCase() + t.substring(1)),
                    selected: _type == t,
                    showCheckmark: false,
                    selectedColor: AppColors.primarySoft,
                    side: BorderSide(
                        color:
                            _type == t ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ]),
              const SizedBox(height: 14),
              AppField(
                  controller: _phone,
                  label: 'Contact phone',
                  keyboardType: TextInputType.phone,
                  validator: requiredValidator),
              const SizedBox(height: 14),
              AppCard(
                onTap: _pickLocation,
                child: Row(children: [
                  Icon(
                      _loc == null
                          ? Icons.add_location_alt_outlined
                          : Icons.location_on_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _loc == null
                                  ? 'Pin your farm on the map'
                                  : 'Location set',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          if (_loc != null)
                            Text(
                                '${_loc!.latitude.toStringAsFixed(4)}, ${_loc!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12.5)),
                        ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
              const SizedBox(height: 14),
              AppField(
                  controller: _address, label: 'Farm address', maxLines: 2),
              const SizedBox(height: 14),
              AppField(
                controller: _upi,
                label: 'UPI ID for direct payments (optional)',
                hint: 'name@bank',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  return RegExp(r'^[\w.\-]{2,256}@[\w]{2,64}$').hasMatch(v)
                      ? null
                      : 'Enter a valid UPI ID, such as name@bank';
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                    'Customers pay this UPI ID directly. You will confirm receipt yourself.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Offer delivery',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _delivery,
                  onChanged: (v) => setState(() => _delivery = v)),
              if (_delivery)
                AppField(
                    controller: _radius,
                    label: 'Delivery radius (km)',
                    keyboardType: TextInputType.number),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Offer pickup at the farm',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _pickup,
                  onChanged: (v) => setState(() => _pickup = v)),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: 'Save farm profile',
                  loading: _busy,
                  onPressed: () => _save(user)),
            ]),
      ),
    );
  }

  Widget _thumb(Widget child, VoidCallback onRemove) => Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Stack(children: [
          child,
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child:
                      Icon(Icons.close_rounded, size: 13, color: Colors.white)),
            ),
          ),
        ]),
      );
}
