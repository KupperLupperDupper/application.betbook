import 'package:betbook/core/money/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountInput.nextRaw', () {
    test('appends digits', () {
      expect(AmountInput.nextRaw('', '5'), '5');
      expect(AmountInput.nextRaw('12', '3'), '123');
    });

    test('replaces a lone leading zero, ignores extra zeros', () {
      expect(AmountInput.nextRaw('0', '5'), '5');
      expect(AmountInput.nextRaw('0', '0'), '0');
    });

    test('allows a single decimal point', () {
      expect(AmountInput.nextRaw('12', 'dot'), '12.');
      expect(AmountInput.nextRaw('12.', 'dot'), '12.'); // no second dot
      expect(AmountInput.nextRaw('', 'dot'), '0.');
    });

    test('caps fractional digits at two', () {
      expect(AmountInput.nextRaw('1.23', '4'), '1.23');
      expect(AmountInput.nextRaw('1.2', '3'), '1.23');
    });

    test('backspace removes the last character', () {
      expect(AmountInput.nextRaw('123', 'back'), '12');
      expect(AmountInput.nextRaw('', 'back'), '');
    });
  });

  group('AmountInput.value', () {
    test('parses complete and partial values', () {
      expect(AmountInput.value('500'), 500);
      expect(AmountInput.value('12.5'), 12.5);
      expect(AmountInput.value('12.'), 12); // trailing dot dropped
    });

    test('null for empty / non-numeric', () {
      expect(AmountInput.value(''), isNull);
      expect(AmountInput.value('.'), isNull);
    });
  });

  group('AmountInput.rawFromMajor', () {
    test('strips trailing zeros and dot', () {
      expect(AmountInput.rawFromMajor(500), '500');
      expect(AmountInput.rawFromMajor(12.5), '12.5');
      expect(AmountInput.rawFromMajor(12.34), '12.34');
    });
  });

  group('AmountInput.display', () {
    test('renders partial decimals naturally (en)', () {
      expect(AmountInput.display('', 'en'), '0');
      expect(AmountInput.display('12.', 'en'), '12.');
      expect(AmountInput.display('1234', 'en'), '1,234');
    });
  });
}
