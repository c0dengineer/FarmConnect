import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class Farm {
  final String id; // equals the farmer uid
  final String farmName, ownerName, description, farmingType, phone, address;
  final List<String> photoUrls;
  final double lat, lng, deliveryRadiusKm, ratingAvg;
  final int ratingCount;
  final bool deliveryAvailable, pickupAvailable, isVerified;
  final DateTime createdAt;

  const Farm({
    required this.id,
    required this.farmName,
    this.ownerName = '',
    this.description = '',
    this.farmingType = 'traditional',
    this.phone = '',
    this.address = '',
    this.photoUrls = const [],
    required this.lat,
    required this.lng,
    this.deliveryRadiusKm = 15,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.deliveryAvailable = true,
    this.pickupAvailable = true,
    this.isVerified = false,
    required this.createdAt,
  });

  factory Farm.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Farm(
      id: d.id,
      farmName: m['farmName'] ?? '',
      ownerName: m['ownerName'] ?? '',
      description: m['description'] ?? '',
      farmingType: m['farmingType'] ?? 'traditional',
      phone: m['phone'] ?? '',
      address: m['address'] ?? '',
      photoUrls: strList(m['photoUrls']),
      lat: dbl(m['lat']),
      lng: dbl(m['lng']),
      deliveryRadiusKm: dbl(m['deliveryRadiusKm'], 15),
      ratingAvg: dbl(m['ratingAvg']),
      ratingCount: integer(m['ratingCount']),
      deliveryAvailable: m['deliveryAvailable'] ?? true,
      pickupAvailable: m['pickupAvailable'] ?? true,
      isVerified: m['isVerified'] ?? false,
      createdAt: dt(m['createdAt']),
    );
  }

  /// Rating fields and isVerified are intentionally excluded: they are managed separately.
  Map<String, dynamic> toMap() => {
        'farmName': farmName,
        'ownerName': ownerName,
        'description': description,
        'farmingType': farmingType,
        'phone': phone,
        'address': address,
        'photoUrls': photoUrls,
        'lat': lat,
        'lng': lng,
        'deliveryRadiusKm': deliveryRadiusKm,
        'deliveryAvailable': deliveryAvailable,
        'pickupAvailable': pickupAvailable,
      };
}
