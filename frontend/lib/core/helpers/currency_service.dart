import 'dart:convert';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:http/http.dart' as http;

class CurrencyConversionException implements Exception {
  CurrencyConversionException(this.message);
  final String message;

  @override
  String toString() => 'CurrencyConversionException: $message';
}

/// Talks to the Frankfurter API (https://frankfurter.dev) — free, no API
/// key required, ECB-sourced daily rates, supports HUF/EUR/USD directly.
/// Swap the base URL + parsing here if you'd rather use a different provider.
class CurrencyService {
  CurrencyService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://api.frankfurter.app';

  /// Returns how many units of [to] you get for 1 unit of [from].
  Future<double> getExchangeRate(Currency from, Currency to) async {
    if (from == to) {
      return 1.0;
    }

    final uri = Uri.parse('$_baseUrl/latest?from=${from.code}&to=${to.code}');

    try {
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw CurrencyConversionException(
          'Failed to fetch rate (status ${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>?;
      final rate = rates?[to.code];

      if (rate == null) {
        throw CurrencyConversionException(
          'Rate for ${to.code} not found in API response',
        );
      }

      return (rate as num).toDouble();
    } on CurrencyConversionException {
      rethrow;
    } catch (e) {
      throw CurrencyConversionException('Network error: $e');
    }
  }

  /// Converts [amount] from [from] currency into [to] currency.
  Future<double> convert({
    required double amount,
    required Currency from,
    required Currency to,
  }) async {
    final rate = await getExchangeRate(from, to);
    return amount * rate;
  }

  void dispose() => _client.close();
}
