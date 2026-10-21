import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmconnect/models/order.dart';
import 'package:farmconnect/models/review.dart';

class ReviewRepo {
  final _db = FirebaseFirestore.instance;

  List<Review> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(Review.fromDoc).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Stream<List<Review>> watchForProduct(String productId) =>
      _db.collection('reviews').where('productIds', arrayContains: productId).snapshots().map(_map);

  Stream<List<Review>> watchForFarm(String farmerUid) =>
      _db.collection('reviews').where('farmerUid', isEqualTo: farmerUid).snapshots().map(_map);

  /// Saves the review and updates running rating averages on the farm and each product.
  Future<void> submit({required FarmOrder order, required int rating, required String comment, required String customerName}) async {
    final reviewRef = _db.collection('reviews').doc();
    final farmRef = _db.collection('farms').doc(order.farmerUid);
    final productRefs = order.items.map((e) => _db.collection('products').doc(e.productId)).toList();

    await _db.runTransaction((tx) async {
      final farmSnap = await tx.get(farmRef);
      final prodSnaps = [for (final r in productRefs) await tx.get(r)];

      Map<String, dynamic> avg(Map<String, dynamic>? d) {
        final c = ((d?['ratingCount'] ?? 0) as num).toInt();
        final a = ((d?['ratingAvg'] ?? 0) as num).toDouble();
        return {'ratingAvg': (a * c + rating) / (c + 1), 'ratingCount': c + 1};
      }

      if (farmSnap.exists) tx.update(farmRef, avg(farmSnap.data()));
      for (final s in prodSnaps) {
        if (s.exists) tx.update(s.reference, avg(s.data()));
      }
      tx.set(reviewRef, {
        'orderId': order.id,
        'farmerUid': order.farmerUid,
        'customerUid': order.customerUid,
        'customerName': customerName,
        'productIds': order.items.map((e) => e.productId).toList(),
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': Timestamp.now(),
      });
      tx.update(_db.collection('orders').doc(order.id), {'reviewed': true});
    });
  }
}
