import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches public FX reference rates from Frankfurter (ECB data, no API key).
///
/// No user data is ever sent — only a public request for currency rates.
/// Rates are returned as *rate-to-base*: base-currency units per 1 unit of the
/// listed currency, matching the app's storage convention.
class FxRateService {
  FxRateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _host = 'api.frankfurter.dev';

  /// Returns a map of `currencyCode -> rateToBase` for [symbols] (the base
  /// currency is excluded/1.0). Throws on network or parsing failure.
  Future<Map<String, double>> fetchRatesToBase({
    required String base,
    required List<String> symbols,
  }) async {
    final wanted = symbols.where((s) => s != base).toList();
    if (wanted.isEmpty) return {};

    final uri = Uri.https(_host, '/v1/latest', {
      'base': base,
      'symbols': wanted.join(','),
    });

    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Rate service returned ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = (body['rates'] as Map<String, dynamic>?) ?? const {};

    // Frankfurter gives "1 base = rates[X] X". We store the inverse:
    // rateToBase[X] = base per 1 X = 1 / rates[X].
    final out = <String, double>{};
    rates.forEach((code, value) {
      final perBase = (value as num).toDouble();
      if (perBase > 0) out[code] = 1 / perBase;
    });
    return out;
  }
}
