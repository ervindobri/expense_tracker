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

  /// [amount] (HUF) converted and formatted with the selected currency symbol.
  String formattedAmount(double amount, {bool showDecimals = false}) {
    return convertedAmount(
      amount,
    ).formatCurrencySymbol(showDecimals: showDecimals, symbol: currency.symbol);
  }
}
