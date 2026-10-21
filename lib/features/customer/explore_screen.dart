import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:farmconnect/all.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  GoogleMapController? _ctrl;
  double? _radius; // null = all

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final all = ref.watch(farmsProvider).valueOrNull ?? [];
    final farms = all.where((f) {
      if (_radius == null || pos == null) return true;
      return distanceKm(pos, f.lat, f.lng)! <= _radius!;
    }).toList();
    if (pos != null) {
      farms.sort((a, b) => distanceKm(pos, a.lat, a.lng)!.compareTo(distanceKm(pos, b.lat, b.lng)!));
    }
    final start = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return Stack(children: [
      if (!kIsWeb) GoogleMap(
        initialCameraPosition: CameraPosition(target: start, zoom: 11),
        onMapCreated: (c) => _ctrl = c,
        myLocationEnabled: pos != null,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        markers: {
          for (final f in farms)
            Marker(
              markerId: MarkerId(f.id),
              position: LatLng(f.lat, f.lng),
              infoWindow: InfoWindow(
                title: f.farmName,
                snippet: pos == null ? f.farmingType : '${fmtDistance(distanceKm(pos, f.lat, f.lng))} away · tap to open',
                onTap: () => context.push('/farm/${f.id}'),
              ),
            ),
        },
      ) else _WebFarmMap(farms: farms, pos: pos),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            for (final r in <double?>[null, 5, 10, 25])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(r == null ? 'All farms' : '${r.toInt()} km'),
                  selected: _radius == r,
                  onSelected: (_) => setState(() => _radius = r),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: _radius == r ? Colors.white : AppColors.text, fontWeight: FontWeight.w600),
                  side: const BorderSide(color: AppColors.border),
                  showCheckmark: false,
                ),
              ),
          ]),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 12,
        child: SizedBox(
          height: 96,
          child: farms.isEmpty
              ? Center(child: Pill('No farms in this range', color: AppColors.muted, bg: Colors.white))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: farms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final f = farms[i];
                    return GestureDetector(
                      onLongPress: () => _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(f.lat, f.lng), 14)),
                      child: FarmTile(farm: f, width: 290, distanceKm: distanceKm(pos, f.lat, f.lng)),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

/// A web-safe neighborhood map surface. The native Google map is used on
/// mobile; the web plugin requires a separately configured Maps JavaScript API.
class _WebFarmMap extends StatelessWidget {
  const _WebFarmMap({required this.farms, required this.pos});
  final List<Farm> farms;
  final dynamic pos;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xffe9eee5),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _MapRoadPainter())),
          if (farms.isNotEmpty)
            ...farms.take(8).toList().asMap().entries.map((e) => Positioned(
                  left: 28 + (e.key % 3) * 104,
                  top: 115 + (e.key ~/ 3) * 72,
                  child: ActionChip(
                    avatar: const Icon(Icons.storefront_outlined, size: 16),
                    label: Text(e.value.farmName, overflow: TextOverflow.ellipsis),
                    onPressed: () => context.push('/farm/${e.value.id}'),
                  ),
                )),
          if (farms.isEmpty)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nearby farms will appear here when growers join FarmConnect.'),
                ),
              ),
            ),
        ]),
      );
}

class _MapRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xfffaf8f3)..strokeWidth = 14..style = PaintingStyle.stroke;
    final thin = Paint()..color = const Color(0xffd5ddcf)..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 25), road);
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 25), thin);
    }
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x + 35, size.height), road);
      canvas.drawLine(Offset(x, 0), Offset(x + 35, size.height), thin);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
