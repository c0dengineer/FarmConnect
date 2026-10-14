import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Returns the device position, or null when permission/service is unavailable.
  static Future<Position?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 12)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Best-effort reverse geocoding.
  static Future<String> addressFor(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng);
      if (list.isEmpty) return '';
      final p = list.first;
      return [p.street, p.subLocality, p.locality, p.postalCode].where((e) => e != null && e.isNotEmpty).join(', ');
    } catch (_) {
      return '';
    }
  }
}
