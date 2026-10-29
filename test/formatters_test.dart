import 'package:farmconnect/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sameDay compares timestamps in the local timezone', () {
    final local = DateTime(2025, 1, 2, 1);
    final utc = local.toUtc();

    expect(sameDay(local, utc), isTrue);
  });

  test('sameDay rejects timestamps on different local calendar days', () {
    final firstDay = DateTime(2025, 1, 2, 23);
    final nextDay = DateTime(2025, 1, 3, 0);

    expect(sameDay(firstDay, nextDay), isFalse);
  });
}
