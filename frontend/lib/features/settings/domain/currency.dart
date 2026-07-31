import 'package:easy_localization/easy_localization.dart';
import 'package:frontend/core/localization/locale_keys.dart';

enum Currency { huf, eur, usd }

const defaultCurrency = Currency.huf;

extension Ext on Currency {
  String get display => switch (this) {
    Currency.huf => 'Forint (Ft)',
    Currency.eur => 'Euro (€)',
    Currency.usd => 'US Dollar (\$)',
  };

  String get symbol => switch (this) {
    Currency.huf => LocaleKeys.ft.tr(),
    Currency.eur => '€',
    Currency.usd => '\$',
  };
}

extension CurrencyCode on Currency {
  String get code {
    switch (this) {
      case Currency.huf:
        return 'HUF';
      case Currency.eur:
        return 'EUR';
      case Currency.usd:
        return 'USD';
    }
  }
}
