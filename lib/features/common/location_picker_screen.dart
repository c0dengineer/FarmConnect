import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:farmconnect/all.dart';

/// Full-screen map. Tap anywhere to drop the pin, then confirm. Pops a LatLng.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});
  final LatLng? initial;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _ctrl = MapController();
  LatLng? _picked;
  String _pickedName = '';
  late LatLng _start;
  bool _mapReady = false;
  int _lookupId = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _start = widget.initial ??
        const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    _picked = widget.initial;
    if (widget.initial != null) _resolveName(widget.initial!);
    if (widget.initial == null) _useMyLocation(silent: true);
  }

  Future<void> _setPicked(LatLng point) async {
    setState(() {
      _picked = point;
      _pickedName = 'Looking up this place…';
    });
    await _resolveName(point);
  }

  Future<void> _resolveName(LatLng point) async {
    final request = ++_lookupId;
    final name =
        await LocationService.addressFor(point.latitude, point.longitude);
    if (!mounted || request != _lookupId) return;
    setState(() => _pickedName = name.isEmpty ? 'Pinned location' : name);
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    final pos = await LocationService.current();
    if (pos == null) {
      if (!silent && mounted) {
        showMsg(context, 'Could not get your location. Tap the map instead.');
      }
      return;
    }
    final p = LatLng(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _picked = p;
      _pickedName = 'Looking up this place…';
    });
    if (_mapReady) _ctrl.move(p, 16);
    await _resolveName(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: Stack(children: [
        FlutterMap(
          mapController: _ctrl,
          options: MapOptions(
            initialCenter: _start,
            initialZoom: 14,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.all),
            onMapReady: () => _mapReady = true,
            onTap: (_, p) => _setPicked(p),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.farmconnect.app',
              maxZoom: 19,
            ),
            if (_picked != null)
              MarkerLayer(markers: [
                Marker(
                  point: _picked!,
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.location_pin,
                      size: 44, color: AppColors.primary),
                ),
              ]),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors')
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 178,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FloatingActionButton.small(
              heroTag: 'location-zoom-in',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () => _ctrl.move(_ctrl.camera.center,
                  (_ctrl.camera.zoom + 1).clamp(3, 19).toDouble()),
              child: const Icon(Icons.add_rounded),
            ),
            const SizedBox(height: 6),
            FloatingActionButton.small(
              heroTag: 'location-zoom-out',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () => _ctrl.move(_ctrl.camera.center,
                  (_ctrl.camera.zoom - 1).clamp(3, 19).toDouble()),
              child: const Icon(Icons.remove_rounded),
            ),
            const SizedBox(height: 6),
            FloatingActionButton.small(
              heroTag: 'location-current',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: _useMyLocation,
              child: const Icon(Icons.my_location_rounded),
            ),
          ]),
        ),
        if (_picked != null)
          Positioned(
            left: 16,
            right: 74,
            bottom: 92,
            child: SafeArea(
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.place_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('SELECTED LOCATION',
                              style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700)),
                          Text(
                              _pickedName.isEmpty
                                  ? 'Finding place name…'
                                  : _pickedName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ])),
                  ]),
                ),
              ),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            child: PrimaryButton(
              label: _picked == null
                  ? 'Tap the map to drop a pin'
                  : 'Confirm this location',
              icon: Icons.check_rounded,
              onPressed: _picked == null ? null : () => context.pop(_picked),
            ),
          ),
        ),
      ]),
    );
  }
}
