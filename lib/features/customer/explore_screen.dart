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
  double? _radius;
  bool _mapReady = false;
  static const _radii = <double?>[null, 1, 3, 5, 10, 25, 50];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _moveTo(LatLng point, {double? zoom}) {
    if (!_mapReady) return;
    _ctrl.move(point, zoom ?? _ctrl.camera.zoom);
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _ctrl.camera;
    _ctrl.move(camera.center, (camera.zoom + delta).clamp(3, 19).toDouble());
  }

  Future<void> _chooseCenter(Position? pos) async {
    if (pos != null) {
      _moveTo(LatLng(pos.latitude, pos.longitude), zoom: 13);
      return;
    }
    final picked = await context.push<LatLng>('/location-picker');
    if (picked == null || !mounted) return;
    final name =
        await LocationService.addressFor(picked.latitude, picked.longitude);
    if (!mounted) return;
    ref.read(userLocationProvider.notifier).select(
          picked.latitude,
          picked.longitude,
          name.isEmpty ? 'Pinned location' : name,
        );
    _moveTo(picked, zoom: 13);
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(userLocationProvider).valueOrNull;
    final placeName = ref.watch(userLocationNameProvider);
    final all = ref.watch(farmsProvider).valueOrNull ?? [];
    final start = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    final origin = pos == null ? start : null;

    ref.listen(userLocationProvider, (previous, next) {
      final p = next.valueOrNull;
      if (p == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _moveTo(LatLng(p.latitude, p.longitude), zoom: 13);
      });
    });

    double distance(Farm farm) => pos != null
        ? distanceKm(pos, farm.lat, farm.lng)!
        : haversineKm(origin!.latitude, origin.longitude, farm.lat, farm.lng);

    final farms = all
        .where((farm) => _radius == null || distance(farm) <= _radius!)
        .toList()
      ..sort((a, b) => distance(a).compareTo(distance(b)));
    final cardWidth =
        (MediaQuery.sizeOf(context).width - 32).clamp(280, 420).toDouble();

    return Stack(children: [
      FlutterMap(
        mapController: _ctrl,
        options: MapOptions(
          initialCenter: start,
          initialZoom: 11,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
          onMapReady: () {
            _mapReady = true;
            if (pos != null) _moveTo(start, zoom: 13);
          },
        ),
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
                  decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.person_pin_circle_rounded,
                      color: AppColors.primary, size: 38),
                ),
              ),
            for (final farm in farms)
              Marker(
                point: LatLng(farm.lat, farm.lng),
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => _showFarm(context, farm, pos, distance(farm)),
                  child: const Icon(Icons.location_pin,
                      color: AppColors.primary, size: 44),
                ),
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
      SafeArea(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  children: _radii
                      .map((radius) => Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ChoiceChip(
                              label: Text(radius == null
                                  ? 'All farms'
                                  : '${radius.toInt()} km'),
                              selected: _radius == radius,
                              onSelected: (_) =>
                                  setState(() => _radius = radius),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                  color: _radius == radius
                                      ? Colors.white
                                      : AppColors.text,
                                  fontWeight: FontWeight.w600),
                              side: const BorderSide(color: AppColors.border),
                              showCheckmark: false,
                            ),
                          ))
                      .toList(),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.filter_alt_outlined,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                    '${farms.length} farms · ${_radius == null ? 'all distances' : 'within ${_radius!.toInt()} km'} · ${placeName ?? 'map center'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  )),
                ]),
              ),
            ]),
      ),
      Positioned(
        right: 14,
        bottom: 155,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FloatingActionButton.small(
            heroTag: 'farms-zoom-in',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: () => _zoomBy(1),
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(height: 6),
          FloatingActionButton.small(
            heroTag: 'farms-zoom-out',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: () => _zoomBy(-1),
            child: const Icon(Icons.remove_rounded),
          ),
          const SizedBox(height: 6),
          FloatingActionButton.small(
            heroTag: 'farms-recenter',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: () => _chooseCenter(pos),
            child: const Icon(Icons.my_location_rounded),
          ),
        ]),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 8,
        child: SizedBox(
          height: 132,
          child: farms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Pill(
                      pos == null && _radius != null
                          ? 'Choose a location to search within a radius'
                          : 'No farms in this range. Try a wider distance.',
                      color: AppColors.muted,
                      bg: Colors.white,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: farms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final farm = farms[i];
                    return FarmTile(
                      farm: farm,
                      width: cardWidth,
                      distanceKm: distance(farm),
                      isNearest: i == 0,
                      onLocate: () =>
                          _moveTo(LatLng(farm.lat, farm.lng), zoom: 14),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

void _showFarm(
    BuildContext context, Farm farm, Position? pos, double distance) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(farm.farmName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(farm.address.isEmpty ? farm.farmingType : farm.address),
              Text(
                  '${fmtDistance(distance)} from ${pos == null ? 'the map center' : 'your location'}'),
              const SizedBox(height: 12),
              PrimaryButton(
                  label: 'View farm and produce',
                  onPressed: () {
                    Navigator.pop(context);
                    GoRouter.of(context).push('/farm/${farm.id}');
                  }),
            ]),
      ),
    ),
  );
}
