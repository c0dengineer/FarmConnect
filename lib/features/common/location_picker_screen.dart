import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        if (!kIsWeb) GoogleMap(
          initialCameraPosition: CameraPosition(target: _start, zoom: 14),
          onMapCreated: (c) => _ctrl = c,
          onTap: (p) => setState(() => _picked = p),
          markers: {if (_picked != null) Marker(markerId: const MarkerId('p'), position: _picked!)},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ) else _WebLocationSurface(
          initial: _start,
          picked: _picked,
          onPick: (p) => setState(() => _picked = p),
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

class _WebLocationSurface extends StatelessWidget {
  const _WebLocationSurface({required this.initial, required this.picked, required this.onPick});
  final LatLng initial;
  final LatLng? picked;
  final ValueChanged<LatLng> onPick;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) => GestureDetector(
        onTapDown: (event) {
          final dx = (event.localPosition.dx / box.maxWidth - .5) * .06;
          final dy = (.5 - event.localPosition.dy / box.maxHeight) * .06;
          onPick(LatLng(initial.latitude + dy, initial.longitude + dx));
        },
        child: Container(
          color: const Color(0xffe9eee5),
          child: Stack(children: [
            const Positioned.fill(child: CustomPaint(painter: _LocationRoadPainter())),
            const Positioned(top: 22, left: 20, right: 20, child: Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Tap the map area to place your farm or delivery pin.')))),
            if (picked != null) Center(child: Icon(Icons.location_on, size: 42, color: AppColors.primary)),
          ]),
        ),
      ));
}

class _LocationRoadPainter extends CustomPainter {
  const _LocationRoadPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xfffaf8f3)..strokeWidth = 18..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * .27), Offset(size.width, size.height * .38), p);
    canvas.drawLine(Offset(size.width * .72, 0), Offset(size.width * .34, size.height), p);
    canvas.drawLine(Offset(0, size.height * .78), Offset(size.width, size.height * .67), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
