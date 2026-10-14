import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:farmconnect/all.dart';

/// Full-screen map. Tap anywhere to drop the pin, then confirm. Pops a LatLng.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});
  final LatLng? initial;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _ctrl;
  LatLng? _picked;
  late LatLng _start;

  @override
  void initState() {
    super.initState();
    _start = widget.initial ?? const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    _picked = widget.initial;
    if (widget.initial == null) _useMyLocation(silent: true);
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    final pos = await LocationService.current();
    if (pos == null) {
      if (!silent && mounted) showMsg(context, 'Could not get your location. Tap the map instead.');
      return;
    }
    final p = LatLng(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() => _picked = p);
    _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _start, zoom: 14),
          onMapCreated: (c) => _ctrl = c,
          onTap: (p) => setState(() => _picked = p),
          markers: {if (_picked != null) Marker(markerId: const MarkerId('p'), position: _picked!)},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          right: 16,
          bottom: 110,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: _useMyLocation,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            child: PrimaryButton(
              label: _picked == null ? 'Tap the map to drop a pin' : 'Confirm this location',
              icon: Icons.check_rounded,
              onPressed: _picked == null ? null : () => context.pop(_picked),
            ),
          ),
        ),
      ]),
    );
  }
}
