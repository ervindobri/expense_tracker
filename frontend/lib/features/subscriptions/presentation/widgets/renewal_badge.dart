import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';

String renewalLabel(int days) => switch (days) {
  0 => LocaleKeys.renews_today.tr(),
  1 => LocaleKeys.renews_tomorrow.tr(),
  _ => LocaleKeys.renews_in_days.tr(namedArgs: {'value': '$days'}),
};

/// Pill showing when [subscription] renews; tinted red when it is close.
/// Inactive subscriptions show their state instead.
class RenewalBadge extends StatelessWidget {
  const RenewalBadge({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final days = subscription.daysUntilRenewal();
    final urgent = subscription.isActive && days <= 2;
    final foreground = urgent
        ? theme.failureColor
        : theme.textColor.withValues(alpha: subscription.isActive ? 0.8 : 0.5);
    return AnimatedContainer(
      duration: kThemeAnimationDuration,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: urgent
            ? theme.failureColor.withValues(alpha: 0.14)
            : theme.indicatorColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        subscription.isActive ? renewalLabel(days) : LocaleKeys.inactive.tr(),
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
