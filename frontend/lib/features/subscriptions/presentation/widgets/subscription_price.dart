import 'package:flutter/material.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// [amount] in [currency], e.g. "10.99 €".
String formatInCurrency(double amount, Currency currency) =>
    amount.formatCurrencySymbol(symbol: currency.symbol);

/// "≈ 4 300 Ft" when [currency] differs from the app's display currency,
/// otherwise null.
String? convertedHint(WidgetRef ref, double amount, Currency currency) {
  if (currency == ref.currency || amount == 0) {
    return null;
  }
  // an estimate, so whole forints are precise enough
  final huf = ref.hufAmount(amount, currency).roundToDouble();
  return '≈ ${ref.formattedAmount(huf)}';
}

/// A subscription's price in its own currency, with the converted value
/// underneath when that currency isn't the one the app displays.
class SubscriptionPrice extends ConsumerWidget {
  const SubscriptionPrice({
    super.key,
    required this.subscription,
    this.style,
    this.crossAxisAlignment = CrossAxisAlignment.end,
  });

  final Subscription subscription;
  final TextStyle? style;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hint = convertedHint(ref, subscription.amount, subscription.currency);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          formatInCurrency(subscription.amount, subscription.currency),
          maxLines: 1,
          style: style,
        ),
        if (hint != null)
          Text(
            hint,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}
