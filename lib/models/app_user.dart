import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class Roles {
  static const customer = 'customer';
  static const farmer = 'farmer';
  static const admin = 'admin';
}

class Address {
  final String label, line1, city, pincode;
  final double? lat, lng;
  const Address({required this.label, required this.line1, required this.city, required this.pincode, this.lat, this.lng});

  String get full => '$line1, $city${pincode.isEmpty ? '' : ' - $pincode'}';

  Map<String, dynamic> toMap() =>
      {'label': label, 'line1': line1, 'city': city, 'pincode': pincode, 'lat': lat, 'lng': lng};

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        label: m['label'] ?? 'Home',
        line1: m['line1'] ?? '',
        city: m['city'] ?? '',
        pincode: m['pincode'] ?? '',
        lat: m['lat'] is num ? (m['lat'] as num).toDouble() : null,
        lng: m['lng'] is num ? (m['lng'] as num).toDouble() : null,
      );
}

class AppUser {
  final String uid, role, name, email, phone;
  final String? photoUrl, fcmToken;
  final bool isBlocked;
  final List<Address> addresses;
  final List<String> favoriteProductIds, followedFarmIds;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl,
    this.fcmToken,
    this.isBlocked = false,
    this.addresses = const [],
    this.favoriteProductIds = const [],
    this.followedFarmIds = const [],
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: d.id,
      role: m['role'] ?? Roles.customer,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      phone: m['phone'] ?? '',
      photoUrl: m['photoUrl'],
      fcmToken: m['fcmToken'],
      isBlocked: m['isBlocked'] ?? false,
      addresses: (m['addresses'] is List)
          ? (m['addresses'] as List).map((e) => Address.fromMap(Map<String, dynamic>.from(e))).toList()
          : [],
      favoriteProductIds: strList(m['favoriteProductIds']),
      followedFarmIds: strList(m['followedFarmIds']),
      createdAt: dt(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'role': role,
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'isBlocked': isBlocked,
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'favoriteProductIds': favoriteProductIds,
        'followedFarmIds': followedFarmIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
