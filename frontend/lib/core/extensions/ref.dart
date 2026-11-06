import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/state/currency_provider.dart';
import 'package:frontend/features/settings/domain/currency.dart';

extension CurrencyExt on WidgetRef {
  // Apply currency conversion
  double convertedAmount(double amount) {
    return watch(convertedAmountProvider(amount)).value ?? amount;
  }

  Currency get currency {
    return watch(currencyProvider);
  }

  /// [amount] given in [currency], converted to HUF. Uses the fallback rate
  /// until the live one has loaded.
  double hufAmount(double amount, Currency currency) {
    if (currency == Currency.huf) {
      return amount;
    }
    final rate =
        watch(toHufRateProvider(currency)).value ?? currency.fallbackToHuf;
    return amount * rate;
  }

  /// [amount] given in [currency], converted to HUF for saving and rounded to
  /// 2 decimals. Reads instead of watching, so it is safe in callbacks; falls
  /// back to the offline rate when the live one can't be fetched.
  Future<double> toHuf(double amount, Currency currency) async {
    if (currency == Currency.huf) {
      return amount;
    }
    double rate;
    try {
      rate = await read(toHufRateProvider(currency).future);
    } catch (_) {
      rate = currency.fallbackToHuf;
    }
    return (amount * rate * 100).round() / 100;
  }

  /// [amount] (HUF) converted and formatted with the selected currency symbol.
  String formattedAmount(double amount, {bool showDecimals = false}) {
    return convertedAmount(
      amount,
    ).formatCurrencySymbol(showDecimals: showDecimals, symbol: currency.symbol);
  }
}
