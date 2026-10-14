import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmconnect/models/harvest_alert.dart';

class AlertRepo {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('harvestAlerts');

  List<HarvestAlert> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(HarvestAlert.fromDoc).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Stream<List<HarvestAlert>> watchByFarmer(String uid) => _col.where('farmerUid', isEqualTo: uid).snapshots().map(_map);

  /// Alerts from followed farms (Firestore whereIn supports up to 30 values).
  Stream<List<HarvestAlert>> watchForFarms(List<String> farmIds) {
    if (farmIds.isEmpty) return Stream.value([]);
    return _col.where('farmerUid', whereIn: farmIds.take(30).toList()).snapshots().map(_map);
  }

  Future<void> post(HarvestAlert a) => _col.add(a.toMap());
  Future<void> delete(String id) => _col.doc(id).delete();
}
