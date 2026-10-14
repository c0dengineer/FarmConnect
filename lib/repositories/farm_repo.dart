import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmconnect/models/farm.dart';

class FarmRepo {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('farms');

  Stream<Farm?> watchFarm(String id) => _col.doc(id).snapshots().map((d) => d.exists ? Farm.fromDoc(d) : null);

  Stream<List<Farm>> watchFarms() => _col.snapshots().map((s) => s.docs.map(Farm.fromDoc).toList());

  /// Creates/updates the farm and syncs name + location to the farmer's products.
  Future<void> saveFarm(Farm farm, {required bool isNew}) async {
    final data = farm.toMap();
    if (isNew) {
      data['createdAt'] = Timestamp.now();
      data['ratingAvg'] = 0;
      data['ratingCount'] = 0;
      data['isVerified'] = false;
      await _col.doc(farm.id).set(data);
    } else {
      await _col.doc(farm.id).update(data);
      final products = await _db.collection('products').where('farmerUid', isEqualTo: farm.id).get();
      if (products.docs.isEmpty) return;
      final batch = _db.batch();
      for (final p in products.docs) {
        batch.update(p.reference, {'farmName': farm.farmName, 'lat': farm.lat, 'lng': farm.lng});
      }
      await batch.commit();
    }
  }

  Future<void> setVerified(String id, bool v) => _col.doc(id).update({'isVerified': v});
}
