import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmconnect/core/utils/freshness.dart';
import 'model_utils.dart';

class Product {
  final String id, farmerUid, farmName, name, category, description, unit;
  final double price, lat, lng, ratingAvg;
  final int quantityAvailable, shelfLifeDays, uglyDiscountPercent, ratingCount, totalSold;
  final List<String> imageUrls;
  final DateTime harvestDate, createdAt;
  final bool isUgly, isOrganic, isAvailable, isPreOrder;
  final String uglyReason;

  const Product({
    required this.id,
    required this.farmerUid,
    required this.farmName,
    required this.name,
    required this.category,
    this.description = '',
    required this.unit,
    required this.price,
    required this.lat,
    required this.lng,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.totalSold = 0,
    required this.quantityAvailable,
    required this.shelfLifeDays,
    this.uglyDiscountPercent = 0,
    this.uglyReason = '',
    this.imageUrls = const [],
    required this.harvestDate,
    required this.createdAt,
    this.isUgly = false,
    this.isOrganic = false,
    this.isAvailable = true,
    this.isPreOrder = false,
  });

  int get freshness => freshnessScore(harvestDate, shelfLifeDays);
  double get effectivePrice => isUgly && uglyDiscountPercent > 0 ? (price * (100 - uglyDiscountPercent) / 100) : price;
  bool get inStock => quantityAvailable > 0;
  bool get isBuyable => isAvailable && inStock && (isPreOrder || freshness > 0);

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Product(
      id: d.id,
      farmerUid: m['farmerUid'] ?? '',
      farmName: m['farmName'] ?? '',
      name: m['name'] ?? '',
      category: m['category'] ?? 'Other',
      description: m['description'] ?? '',
      unit: m['unit'] ?? 'kg',
      price: dbl(m['price']),
      lat: dbl(m['lat']),
      lng: dbl(m['lng']),
      ratingAvg: dbl(m['ratingAvg']),
      ratingCount: integer(m['ratingCount']),
      totalSold: integer(m['totalSold']),
      quantityAvailable: integer(m['quantityAvailable']),
      shelfLifeDays: integer(m['shelfLifeDays'], 7),
      uglyDiscountPercent: integer(m['uglyDiscountPercent']),
      uglyReason: m['uglyReason'] ?? '',
      imageUrls: strList(m['imageUrls']),
      harvestDate: dt(m['harvestDate']),
      createdAt: dt(m['createdAt']),
      isUgly: m['isUgly'] ?? false,
      isOrganic: m['isOrganic'] ?? false,
      isAvailable: m['isAvailable'] ?? true,
      isPreOrder: m['isPreOrder'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'farmerUid': farmerUid,
        'farmName': farmName,
        'name': name,
        'category': category,
        'description': description,
        'unit': unit,
        'price': price,
        'lat': lat,
        'lng': lng,
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'totalSold': totalSold,
        'quantityAvailable': quantityAvailable,
        'shelfLifeDays': shelfLifeDays,
        'uglyDiscountPercent': uglyDiscountPercent,
        'uglyReason': uglyReason,
        'imageUrls': imageUrls,
        'harvestDate': Timestamp.fromDate(harvestDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.now(),
        'isUgly': isUgly,
        'isOrganic': isOrganic,
        'isAvailable': isAvailable,
        'isPreOrder': isPreOrder,
      };
}
