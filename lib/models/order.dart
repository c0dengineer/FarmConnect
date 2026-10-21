import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class OrderStatus {
  static const placed = 'placed';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const packed = 'packed';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const active = [placed, accepted, packed, outForDelivery];

  static String label(String s) {
    switch (s) {
      case placed:
        return 'Placed';
      case accepted:
        return 'Accepted';
      case rejected:
        return 'Rejected';
      case packed:
        return 'Packed';
      case outForDelivery:
        return 'Out for delivery';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return s;
    }
  }

  /// Actions available to the farmer: (button label, next status, isDestructive).
  static List<(String, String, bool)> farmerActions(FarmOrder o) {
    switch (o.status) {
      case placed:
        return [('Accept order', accepted, false), ('Reject', rejected, true)];
      case accepted:
        return [('Mark as packed', packed, false)];
      case packed:
        return o.fulfillment == 'delivery'
            ? [('Out for delivery', outForDelivery, false)]
            : [('Handed over (picked up)', delivered, false)];
      case outForDelivery:
        return [('Mark delivered', delivered, false)];
      default:
        return [];
    }
  }
}

class OrderItem {
  final String productId, name, unit;
  final String? imageUrl;
  final double price, qty;
  final bool isUgly;
  const OrderItem({
    required this.productId,
    required this.name,
    required this.unit,
    this.imageUrl,
    required this.price,
    required this.qty,
    this.isUgly = false,
  });

  double get total => price * qty;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'unit': unit,
        'imageUrl': imageUrl,
        'price': price,
        'qty': qty,
        'isUgly': isUgly,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        unit: m['unit'] ?? '',
        imageUrl: m['imageUrl'],
        price: dbl(m['price']),
        qty: dbl(m['qty'], 1),
        isUgly: m['isUgly'] ?? false,
      );
}

class StatusEntry {
  final String status;
  final DateTime at;
  const StatusEntry(this.status, this.at);
}

class FarmOrder {
  final String id, customerUid, customerName, customerPhone, farmerUid, farmName, farmPhone;
  final List<OrderItem> items;
  final double subtotal, deliveryFee, total, distanceKm;
  final String fulfillment, address, paymentMethod, paymentStatus, paymentUpiId, status, note;
  final List<StatusEntry> history;
  final DateTime createdAt;
  final bool reviewed;

  const FarmOrder({
    required this.id,
    required this.customerUid,
    required this.customerName,
    this.customerPhone = '',
    required this.farmerUid,
    required this.farmName,
    this.farmPhone = '',
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.distanceKm = 0,
    required this.fulfillment,
    required this.address,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.paymentUpiId = '',
    required this.status,
    this.note = '',
    this.history = const [],
    required this.createdAt,
    this.reviewed = false,
  });

  factory FarmOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return FarmOrder(
      id: d.id,
      customerUid: m['customerUid'] ?? '',
      customerName: m['customerName'] ?? '',
      customerPhone: m['customerPhone'] ?? '',
      farmerUid: m['farmerUid'] ?? '',
      farmName: m['farmName'] ?? '',
      farmPhone: m['farmPhone'] ?? '',
      items: (m['items'] is List)
          ? (m['items'] as List).map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e))).toList()
          : [],
      subtotal: dbl(m['subtotal']),
      deliveryFee: dbl(m['deliveryFee']),
      total: dbl(m['total']),
      distanceKm: dbl(m['distanceKm']),
      fulfillment: m['fulfillment'] ?? 'delivery',
      address: m['address'] ?? '',
      paymentMethod: m['paymentMethod'] ?? 'cod',
      paymentStatus: m['paymentStatus'] ?? 'pending',
      paymentUpiId: m['paymentUpiId'] ?? '',
      status: m['status'] ?? OrderStatus.placed,
      note: m['note'] ?? '',
      history: (m['statusHistory'] is List)
          ? (m['statusHistory'] as List).map((e) {
              final x = Map<String, dynamic>.from(e);
              return StatusEntry(x['status'] ?? '', dt(x['at']));
            }).toList()
          : [],
      createdAt: dt(m['createdAt']),
      reviewed: m['reviewed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'customerUid': customerUid,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'farmerUid': farmerUid,
        'farmName': farmName,
        'farmPhone': farmPhone,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'distanceKm': distanceKm,
        'fulfillment': fulfillment,
        'address': address,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'paymentUpiId': paymentUpiId,
        'status': status,
        'note': note,
        'statusHistory': history.map((e) => {'status': e.status, 'at': Timestamp.fromDate(e.at)}).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.now(),
        'reviewed': reviewed,
      };
}
