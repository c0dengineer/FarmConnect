import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class HarvestAlert {
  final String id, farmerUid, farmName, title, message;
  final DateTime createdAt;
  const HarvestAlert({
    required this.id,
    required this.farmerUid,
    required this.farmName,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory HarvestAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return HarvestAlert(
      id: d.id,
      farmerUid: m['farmerUid'] ?? '',
      farmName: m['farmName'] ?? '',
      title: m['title'] ?? '',
      message: m['message'] ?? '',
      createdAt: dt(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'farmerUid': farmerUid,
        'farmName': farmName,
        'title': title,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
