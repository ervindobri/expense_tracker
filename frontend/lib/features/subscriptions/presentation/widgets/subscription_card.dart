import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/renewal_badge.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_avatar.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_detail_sheet.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_price.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Row in the subscriptions list.
class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;
    final subtitle = [
      subscription.period.label,
      if (subscription.isActive)
        subscription.nextRenewal().formatDateOnly
      else
        ref.formattedAmount(subscription.totalSpent),
    ].join(' · ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Material(
        color: FluentTheme.of(context).cardColor,
        child: InkWell(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(openSubscriptionDetails(context, subscription.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              spacing: 12,
              children: [
                SubscriptionAvatar(subscription: subscription),
                Expanded(
                  child: Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: hint),
                      ),
                    ],
                  ),
                ),
                Column(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SubscriptionPrice(
                      subscription: subscription,
                      style: textTheme.bodyLarge,
                    ),
                    RenewalBadge(subscription: subscription),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact tile for the horizontal "renewing soon" row.
class RenewingSoonCard extends ConsumerWidget {
  const RenewingSoonCard({super.key, required this.subscription});

  static const width = 156.0;
  static const height = 132.0;

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(openSubscriptionDetails(context, subscription.id));
          },
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: theme.indicatorColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SubscriptionAvatar(subscription: subscription, radius: 16),
                    Flexible(child: RenewalBadge(subscription: subscription)),
                  ],
                ),
                const Spacer(),
                Text(
                  subscription.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (subscription.amount > 0)
                  SubscriptionPrice(
                    subscription: subscription,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  )
                else
                  Text(
                    subscription.period.label,
                    maxLines: 1,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder in the "renewing soon" row when nothing is due.
class NothingRenewingSoon extends StatelessWidget {
  const NothingRenewingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(LucideIcons.calendarCheck, color: Theme.of(context).hintColor),
          Flexible(
            child: Text(
              LocaleKeys.nothing_renewing_soon.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
