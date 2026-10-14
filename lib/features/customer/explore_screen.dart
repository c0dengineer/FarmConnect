import 'package:flutter/material.dart';
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
      GoogleMap(
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
