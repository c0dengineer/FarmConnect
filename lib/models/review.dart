import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class Review {
  final String id, orderId, farmerUid, customerUid, customerName, comment;
  final List<String> productIds;
  final int rating;
  final DateTime createdAt;
  const Review({
    required this.id,
    required this.orderId,
    required this.farmerUid,
    required this.customerUid,
    required this.customerName,
    required this.productIds,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Review(
      id: d.id,
      orderId: m['orderId'] ?? '',
      farmerUid: m['farmerUid'] ?? '',
      customerUid: m['customerUid'] ?? '',
      customerName: m['customerName'] ?? 'Customer',
      productIds: strList(m['productIds']),
      rating: integer(m['rating'], 5),
      comment: m['comment'] ?? '',
      createdAt: dt(m['createdAt']),
    );
  }
}
