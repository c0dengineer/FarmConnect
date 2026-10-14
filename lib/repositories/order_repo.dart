import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmconnect/models/order.dart';

class OrderRepo {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('orders');

  List<FarmOrder> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(FarmOrder.fromDoc).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Stream<List<FarmOrder>> watchForCustomer(String uid) =>
      _col.where('customerUid', isEqualTo: uid).snapshots().map(_map);

  Stream<List<FarmOrder>> watchForFarmer(String uid) =>
      _col.where('farmerUid', isEqualTo: uid).snapshots().map(_map);

  Stream<List<FarmOrder>> watchRecent() => _col.orderBy('createdAt', descending: true).limit(30).snapshots().map(_map);

  Stream<FarmOrder?> watchById(String id) => _col.doc(id).snapshots().map((d) => d.exists ? FarmOrder.fromDoc(d) : null);

  Future<int> count() async => (await _col.count().get()).count ?? 0;

  /// Places an order and reduces stock atomically so items cannot be oversold.
  Future<String> placeOrder(FarmOrder o) async {
    final ref = _col.doc();
    await _db.runTransaction((tx) async {
      final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final it in o.items) {
        snaps[it.productId] = await tx.get(_db.collection('products').doc(it.productId));
      }
      for (final it in o.items) {
        final s = snaps[it.productId]!;
        if (!s.exists) throw Exception('${it.name} is no longer available.');
        final q = ((s.data()?['quantityAvailable'] ?? 0) as num).toInt();
        if (q < it.qty) throw Exception(q == 0 ? '${it.name} is sold out.' : 'Only $q left of ${it.name}.');
      }
      for (final it in o.items) {
        tx.update(_db.collection('products').doc(it.productId), {
          'quantityAvailable': FieldValue.increment(-it.qty),
          'totalSold': FieldValue.increment(it.qty),
          'updatedAt': Timestamp.now(),
        });
      }
      tx.set(ref, o.toMap());
    });
    return ref.id;
  }

  /// Moves an order to a new status. Rejecting/cancelling puts the stock back.
  Future<void> updateStatus(FarmOrder o, String status) async {
    final ref = _col.doc(o.id);
    final entry = {'status': status, 'at': Timestamp.now()};
    final update = <String, dynamic>{
      'status': status,
      'statusHistory': FieldValue.arrayUnion([entry]),
      'updatedAt': Timestamp.now(),
      if (status == OrderStatus.delivered && o.paymentMethod == 'cod') 'paymentStatus': 'paid',
    };
    final restock = status == OrderStatus.rejected || status == OrderStatus.cancelled;
    if (!restock) {
      await ref.update(update);
      return;
    }
    await _db.runTransaction((tx) async {
      final cur = await tx.get(ref);
      if (cur.data()?['status'] != OrderStatus.placed) {
        throw Exception('This order can no longer be changed.');
      }
      for (final it in o.items) {
        tx.update(_db.collection('products').doc(it.productId), {
          'quantityAvailable': FieldValue.increment(it.qty),
          'totalSold': FieldValue.increment(-it.qty),
          'updatedAt': Timestamp.now(),
        });
      }
      tx.update(ref, update);
    });
  }
}
