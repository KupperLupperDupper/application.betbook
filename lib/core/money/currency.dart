/// Static information about a supported currency.
class CurrencyInfo {
  const CurrencyInfo(this.code, this.symbol, this.name);

  /// ISO-4217 code, e.g. `DKK`.
  final String code;

  /// Display symbol, e.g. `kr.`
  final String symbol;

  /// English display name (localised names are not needed for a code list).
  final String name;
}

/// Currencies offered in pickers. The user can still track any of these per
/// site; the list is intentionally short and betting-market focused.
const List<CurrencyInfo> kSupportedCurrencies = [
  CurrencyInfo('DKK', 'kr.', 'Danish krone'),
  CurrencyInfo('EUR', '€', 'Euro'),
  CurrencyInfo('USD', r'$', 'US dollar'),
  CurrencyInfo('GBP', '£', 'British pound'),
  CurrencyInfo('SEK', 'kr', 'Swedish krona'),
  CurrencyInfo('NOK', 'kr', 'Norwegian krone'),
  CurrencyInfo('PLN', 'zł', 'Polish złoty'),
  CurrencyInfo('CHF', 'CHF', 'Swiss franc'),
  CurrencyInfo('CAD', r'C$', 'Canadian dollar'),
  CurrencyInfo('AUD', r'A$', 'Australian dollar'),
];

final Map<String, CurrencyInfo> _byCode = {
  for (final c in kSupportedCurrencies) c.code: c,
};

CurrencyInfo? currencyInfoFor(String code) => _byCode[code.toUpperCase()];

String currencySymbolFor(String code) =>
    _byCode[code.toUpperCase()]?.symbol ?? code.toUpperCase();
