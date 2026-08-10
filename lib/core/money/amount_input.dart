import 'package:intl/intl.dart';

/// Pure helpers for the custom numeric amount entry shared by the full editor
/// and the quick-add sheet. The canonical model is a raw string of digits with
/// an optional single `.` separator, e.g. `"500"`, `"12.5"`, `"12."`.
class AmountInput {
  const AmountInput._();

  /// The locale's decimal separator (`,` in Danish, `.` in English).
  static String decimalSeparator(String locale) =>
      NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;

  /// Pure transition for a keypad tap on [raw]. [key] is `'0'..'9'`, `'dot'`,
  /// or `'back'`. Enforces one decimal separator, at most two fractional
  /// digits, and no leading-zero runs.
  static String nextRaw(String raw, String key) {
    if (key == 'back') {
      return raw.isEmpty ? raw : raw.substring(0, raw.length - 1);
    }
    if (key == 'dot') {
      if (raw.contains('.')) return raw;
      return raw.isEmpty ? '0.' : '$raw.';
    }
    // A digit.
    if (raw.contains('.')) {
      final fraction = raw.split('.')[1];
      if (fraction.length >= 2) return raw;
      return '$raw$key';
    }
    if (raw == '0') {
      // Replace a lone leading zero; ignore additional zeros.
      return key == '0' ? raw : key;
    }
    return '$raw$key';
  }

  /// The parsed major-unit value of [raw], or null when empty / not a number.
  static double? value(String raw) {
    if (raw.isEmpty) return null;
    var s = raw;
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Renders [raw] with the locale's grouping and decimal separator, keeping
  /// partially-typed values (e.g. `"12."`) natural. Empty renders `"0"`.
  static String display(String raw, String locale) {
    if (raw.isEmpty) return '0';
    final decSep = decimalSeparator(locale);
    final parts = raw.split('.');
    final intText = parts[0].isEmpty ? '0' : parts[0];
    final grouped =
        NumberFormat.decimalPattern(locale).format(int.tryParse(intText) ?? 0);
    if (parts.length == 1) return grouped;
    return '$grouped$decSep${parts[1]}';
  }

  /// Builds a canonical raw string from a major-unit value (`.` separator,
  /// trailing zeros stripped) for prefilling.
  static String rawFromMajor(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
