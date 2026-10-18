import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/state/currency_provider.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/presentation/state/subscriptions_provider.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

/// Active subscription count and total spent on subscriptions, with the
/// estimated monthly cost underneath.
class SubscriptionSummaryCard extends ConsumerWidget {
  const SubscriptionSummaryCard({super.key, required this.summary});

  final SubscriptionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final symbol = ref.watch(currencyProvider).symbol;
    final labelStyle = textTheme.bodySmall?.copyWith(
      color: Theme.of(context).hintColor,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.gradientBorderColors2,
          ),
          width: 1,
        ),
      ),
      child: Column(
        spacing: 20,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.subscriptions.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                      NumberFlow(
                        value: summary.activeCount,
                        locale: context.locale.languageCode,
                        style: textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 32,
                  thickness: 0.5,
                  color: theme.dividerColor,
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LocaleKeys.total_spent.tr(), style: labelStyle),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          spacing: 4,
                          children: [
                            NumberFlow(
                              value: ref.convertedAmount(summary.totalSpent),
                              motionBlur: 4.0,
                              locale: context.locale.languageCode,
                              format: const NumberFlowFormat.currency(
                                maxFraction: 0,
                                sign: SignDisplay.negative,
                                currencyCode: '',
                              ),
                              style: textTheme.headlineLarge,
                            ),
                            Text(symbol, style: textTheme.headlineLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (summary.monthlyCost > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Icon(
                    LucideIcons.repeat,
                    size: 16,
                    color: Theme.of(context).hintColor,
                  ),
                  Text(
                    LocaleKeys.per_month_estimate.tr(
                      namedArgs: {
                        'value': ref.formattedAmount(
                          summary.monthlyCost.roundToDouble(),
                        ),
                      },
                    ),
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
