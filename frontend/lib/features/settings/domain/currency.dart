enum Currency {
  huf, eur, usd
}


const defaultCurrency = Currency.huf;

extension Ext on Currency {
  String get display => switch (this) {
    Currency.huf => 'Forint (Ft)',
    Currency.eur => 'Euro (€)',
    Currency.usd => 'US Dollar (\$)',
  };
}