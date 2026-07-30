extension StringExt on String? {
  String get formatCurrency {
    return CurrencyFormatter.format(num.tryParse(this ?? '') ?? 0.0);
  }

  double? get parseHungarianDecimal {
    final normalized = this
        ?.replaceAll(' ', '') // strip thousands separators
        .replaceAll(
          '\u00A0',
          '',
        ) // strip non-breaking spaces too, if you used them earlier
        .replaceAll(',', '.');
    return double.tryParse(normalized ?? '');
  }
}

extension DoubleExt on double {
  String get formatCurrency {
    return CurrencyFormatter.format(this, alwaysShowDecimals: true);
  }

  String formatCurrencySymbol({bool showDecimals = false}) {
    return CurrencyFormatter.format(
      this,
      alwaysShowDecimals: showDecimals,
      showSymbol: true,
    );
  }
}

extension NumExt on num {
  String get formatCurrency {
    return CurrencyFormatter.format(this, alwaysShowDecimals: true);
  }

  String get formatCurrencySymbol {
    return CurrencyFormatter.format(
      this,
      alwaysShowDecimals: true,
      showSymbol: true,
    );
  }
}

extension IntExt on int {

  String get toMonthLabel => switch (this) {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December',
    _ => toString(),
  };

  String get toMonthLabelShort => switch (this) {
    1 => 'J',
    2 => 'F',
    3 => 'M',
    4 => 'A',
    5 => 'M',
    6 => 'J',
    7 => 'J',
    8 => 'A',
    9 => 'S',
    10 => 'O',
    11 => 'N',
    12 => 'D',
    _ => toString().substring(0, 1),
  };

    (int first, int last) get weekLimits {
    return switch (this) {
      1 => (1, 6),
      2 => (7, 13),
      3 => (14, 20),
      4 => (21, 27),
      5 => (28, 31), // some months have until 30 only (except February)
      _ => (1, 31),
    };
  }
  
  String get formatCurrency {
    return CurrencyFormatter.format(this);
  }

  String get formatCurrencySymbol {
    return CurrencyFormatter.format(this, showSymbol: true);
  }
}


extension DateTimeExt on DateTime {
  // limits: 1-6, 7-13, 14-20, 21-27, 2
  int get currentWeek => day < 7
      ? 1
      : day < 14
      ? 2
      : day < 21
      ? 3
      : day < 28
      ? 4
      : 5;
}


// ignore: avoid_classes_with_only_static_members
class CurrencyFormatter {
  /// Formats a numeric amount as Hungarian Forint, e.g.:
  /// 123        → "123 Ft"
  /// 12345.67   → "12 345,67 Ft"
  /// 123456     → "123 456 Ft"
  ///
  /// Decimals are omitted when the amount is a whole number,
  /// unless [alwaysShowDecimals] is true.
  static String format(
    num amount, {
    bool alwaysShowDecimals = false,
    bool showSymbol = false,
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final fixed = absAmount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    final groupedWhole = _groupThousands(wholePart);

    final showDecimals = alwaysShowDecimals || decimalPart != '00';
    final numberPart = showDecimals
        ? '$groupedWhole,$decimalPart'
        : groupedWhole;

    return '${isNegative ? '-' : ''}$numberPart${showSymbol ? ' Ft' : ''}';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
