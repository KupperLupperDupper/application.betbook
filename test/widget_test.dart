import 'package:betbook/core/stats/summaries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('convertMinorToBase', () {
    test('applies the currency rate to a minor amount', () {
      // 100.00 EUR at 7.46 DKK/EUR = 746.00 DKK.
      final base = convertMinorToBase(10000, 'EUR', {'EUR': 7.46});
      expect(base, closeTo(746.0, 0.0001));
    });

    test('missing rate falls back to 1:1', () {
      final base = convertMinorToBase(5000, 'ZZZ', const {});
      expect(base, closeTo(50.0, 0.0001));
    });
  });
}
