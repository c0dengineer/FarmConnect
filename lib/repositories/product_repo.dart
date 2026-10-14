import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmconnect/models/product.dart';

class ProductRepo {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('products');

  List<Product> _map(QuerySnapshot<Map<String, dynamic>> s) => s.docs.map(Product.fromDoc).toList();

  Stream<List<Product>> watchAvailable() => _col.where('isAvailable', isEqualTo: true).snapshots().map(_map);

  Stream<List<Product>> watchAll() => _col.snapshots().map(_map);

  Stream<List<Product>> watchByFarmer(String uid) => _col
      .where('farmerUid', isEqualTo: uid)
      .snapshots()
      .map((s) => _map(s)..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<Product?> watchById(String id) => _col.doc(id).snapshots().map((d) => d.exists ? Product.fromDoc(d) : null);

  Future<void> save(Product p, {required bool isNew}) async {
    if (isNew) {
      await _col.add(p.toMap());
    } else {
      final data = p.toMap()..remove('createdAt');
      await _col.doc(p.id).update(data);
    }
  }

  Future<void> setAvailable(String id, bool v) => _col.doc(id).update({'isAvailable': v, 'updatedAt': Timestamp.now()});

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> logSearch(String uid, String query, String category) async {
    if (query.trim().isEmpty) return;
    try {
      await _db.collection('searchLogs').add({
        'uid': uid,
        'query': query.trim().toLowerCase(),
        'category': category,
        'createdAt': Timestamp.now(),
      });
    } catch (_) {}
  }
}
