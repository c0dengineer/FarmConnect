import 'package:flutter_test/flutter_test.dart';
import 'package:farmconnect/core/utils/distance_utils.dart';
import 'package:farmconnect/core/utils/freshness.dart';

void main() {
  test('freshness is 100 for a just-harvested item', () {
    expect(freshnessScore(DateTime.now(), 7), 100);
  });

  test('freshness halves at half the shelf life', () {
    final harvested = DateTime.now().subtract(const Duration(hours: 84)); // 3.5 days of 7
    expect(freshnessScore(harvested, 7), inInclusiveRange(49, 51));
  });

  test('freshness is 0 after shelf life ends', () {
    expect(freshnessScore(DateTime.now().subtract(const Duration(days: 10)), 7), 0);
  });

  test('discount suggestion grows as freshness drops', () {
    expect(suggestedDiscount(80), 0);
    expect(suggestedDiscount(55), 10);
    expect(suggestedDiscount(20), 25);
  });

  test('haversine Mumbai -> Pune is roughly 120 km', () {
    final d = haversineKm(19.0760, 72.8777, 18.5204, 73.8567);
    expect(d, inInclusiveRange(110, 125));
  });
}
