import 'package:betbook/core/stats/responsible_gambling.dart';
import 'package:betbook/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('periodStart', () {
    test('daily is midnight of the same day', () {
      final now = DateTime(2026, 8, 12, 14, 30);
      expect(periodStart(LimitPeriod.daily, now), DateTime(2026, 8, 12));
    });

    test('weekly is the Monday of the current week', () {
      // 2026-08-12 is a Wednesday → Monday is 2026-08-10.
      final wed = DateTime(2026, 8, 12, 9);
      expect(periodStart(LimitPeriod.weekly, wed), DateTime(2026, 8, 10));
      // A Monday returns itself.
      final mon = DateTime(2026, 8, 10, 23);
      expect(periodStart(LimitPeriod.weekly, mon), DateTime(2026, 8, 10));
    });

    test('monthly is the first of the month', () {
      final now = DateTime(2026, 8, 29, 1);
      expect(periodStart(LimitPeriod.monthly, now), DateTime(2026, 8));
    });
  });
}
