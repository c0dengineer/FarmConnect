import 'dart:math';
import 'package:geolocator/geolocator.dart';

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(a));
}

/// Distance from the user's position to a point, or null when location unknown.
double? distanceKm(Position? pos, double lat, double lng) {
  if (pos == null) return null;
  return haversineKm(pos.latitude, pos.longitude, lat, lng);
}
