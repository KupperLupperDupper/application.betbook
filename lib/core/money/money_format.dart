import 'package:intl/intl.dart';

import 'currency.dart';

/// All amounts in the database are stored in **minor units** (2 decimals).
const int kMinorUnitsPerMajor = 100;

double minorToMajor(int minor) => minor / kMinorUnitsPerMajor;

int majorToMinor(double major) => (major * kMinorUnitsPerMajor).round();

/// Formats an amount held in [minor] units of [currencyCode] for [localeName]
/// (e.g. `en`, `da`). When [withSign] is true a leading `+`/`−` is shown, which
/// is how net results are displayed.
String formatMinor(
  int minor,
  String currencyCode, {
  required String localeName,
  bool withSign = false,
}) {
  return formatMajor(
    minorToMajor(minor),
    currencyCode,
    localeName: localeName,
    withSign: withSign,
  );
}

/// Formats a [value] already expressed in major units of [currencyCode].
/// Base-currency totals are computed as doubles and formatted through here.
String formatMajor(
  double value,
  String currencyCode, {
  required String localeName,
  bool withSign = false,
}) {
  final format = NumberFormat.currency(
    locale: localeName,
    symbol: currencySymbolFor(currencyCode),
    decimalDigits: 2,
  );

  if (!withSign) {
    return format.format(value);
  }

  // Use a real minus sign and an explicit plus for clarity on net figures.
  final magnitude = format.format(value.abs());
  if (value > 0) return '+$magnitude';
  if (value < 0) return '−$magnitude';
  return magnitude;
}

/// A compact, symbol-only amount (no grouping fuss) for dense chart labels.
String formatCompactMajor(
  double value,
  String currencyCode, {
  required String localeName,
}) {
  final format = NumberFormat.compactCurrency(
    locale: localeName,
    symbol: currencySymbolFor(currencyCode),
  );
  return format.format(value);
}
