import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmconnect/all.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final MapController _ctrl = MapController();
  double? _radius; // null = all

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
      FlutterMap(
        mapController: _ctrl,
        options: MapOptions(initialCenter: start, initialZoom: 11),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.farmconnect.app',
            maxZoom: 19,
          ),
          MarkerLayer(markers: [
            if (pos != null)
              Marker(
                point: start,
                width: 42,
                height: 42,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.person_pin_circle_rounded, color: Colors.blueGrey, size: 38),
                ),
              ),
            for (final f in farms)
              Marker(
                point: LatLng(f.lat, f.lng),
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => _showFarm(context, f, pos),
                  child: const Icon(Icons.location_pin, color: AppColors.primary, size: 44),
                ),
              ),
          ]),
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
          ),
        ],
      ),
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
                      onLongPress: () => _ctrl.move(LatLng(f.lat, f.lng), 14),
                      child: FarmTile(
                        farm: f,
                        width: 290,
                        distanceKm: distanceKm(pos, f.lat, f.lng),
                        isNearest: pos != null && i == 0,
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

void _showFarm(BuildContext context, Farm farm, Position? pos) {
  final distance = distanceKm(pos, farm.lat, farm.lng);
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(farm.farmName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Farm coordinates: ${farm.lat.toStringAsFixed(5)}, ${farm.lng.toStringAsFixed(5)}'),
          if (distance != null) Text('${fmtDistance(distance)} from your location'),
          const SizedBox(height: 12),
          PrimaryButton(label: 'View farm and produce', onPressed: () {
            Navigator.pop(context);
            GoRouter.of(context).push('/farm/${farm.id}');
          }),
        ]),
      ),
    ),
  );
}
