import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/helpers/currency_service.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'currency_provider.g.dart';

@riverpod
class CurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() {
    // TODO: store & load from shared prefs
    return defaultCurrency;
  }

  void set(Currency c) {
    state = c;
  }
}
// -----------------------------------------------------------------------
// Assumed to already exist elsewhere in your app — the currently selected
// display currency. Left here commented out as a reference only; delete
// this block once you wire the file into your real project.
//
// final currencyProvider = StateProvider<Currency>((ref) => Currency.huf);
// -----------------------------------------------------------------------

/// Provides the CurrencyService. Kept as a plain Provider since the
/// service is stateless aside from its http.Client.
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final service = CurrencyService();
  ref.onDispose(service.dispose);
  return service;
});

/// The rate to multiply a HUF amount by to get its value in whatever
/// currency is currently selected in [currencyProvider]. Re-fetches
/// automatically whenever the selected currency changes.
/// Returns 1.0 (no network call) when HUF is selected.
final hufExchangeRateProvider = FutureProvider<double>((ref) async {
  final selectedCurrency = ref.watch(currencyProvider);

  if (selectedCurrency == Currency.huf) {
    return 1.0;
  }
  // TODO: store exchange rate to shared prefs & read back
  final service = ref.watch(currencyServiceProvider);
  return service.getExchangeRate(Currency.huf, selectedCurrency);
});

/// Convenience: converts a HUF [amountInHuf] into the currently-selected
/// currency. Use this directly in widgets when you just need a display value.
final convertedAmountProvider = FutureProvider.family<double, double>((
  ref,
  amountInHuf,
) async {

  if (ref.watch(hufExchangeRateProvider).value == null) {
    return amountInHuf;
  }
  // At this point we must have exchange rate already
  final rate = ref.watch(hufExchangeRateProvider).value!;
  return double.parse((amountInHuf * rate).toStringAsFixed(2));
});
