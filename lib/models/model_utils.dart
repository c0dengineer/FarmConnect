import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dt(dynamic v, [DateTime? fallback]) => v is Timestamp ? v.toDate() : (fallback ?? DateTime.now());
double dbl(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
int integer(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
List<String> strList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];
