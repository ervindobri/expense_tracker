import 'package:flutter/material.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/renewal_badge.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_summary_card.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _path = 'features/subscriptions';

Subscription _subscription(BuildContext context) {
  final period = context.knobs.object.dropdown(
    label: 'Period',
    options: SubscriptionPeriod.values,
    initialOption: SubscriptionPeriod.monthly,
    labelBuilder: (p) => p.name,
  );
  // created so that the next renewal lands `daysUntil` days from today
  final daysUntil = context.knobs.int.slider(
    label: 'Days until renewal',
    initialValue: 3,
    max: 13,
  );
  final now = DateTime.now();
  final renewal = DateTime(now.year, now.month, now.day + daysUntil);
  return Subscription(
    id: context.knobs.int.slider(label: 'Color (id)', initialValue: 1, max: 9),
    name: context.knobs.string(label: 'Name', initialValue: 'Phone'),
    amount: context.knobs.double.input(label: 'Price', initialValue: 5000),
    currency: context.knobs.object.dropdown(
      label: 'Currency',
      options: Currency.values,
      labelBuilder: (c) => c.code,
    ),
    period: period,
    createdDate: period.advance(renewal, -1),
    isActive: context.knobs.boolean(label: 'Active', initialValue: true),
    totalSpent: 45000,
  );
}

@widgetbook.UseCase(name: 'Default', type: SubscriptionCard, path: _path)
Widget subscriptionCardUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 400,
      child: SubscriptionCard(subscription: _subscription(context)),
    ),
  );
}

@widgetbook.UseCase(name: 'Default', type: RenewingSoonCard, path: _path)
Widget renewingSoonCardUseCase(BuildContext context) {
  return Center(child: RenewingSoonCard(subscription: _subscription(context)));
}

@widgetbook.UseCase(name: 'Default', type: RenewalBadge, path: _path)
Widget renewalBadgeUseCase(BuildContext context) {
  return Center(child: RenewalBadge(subscription: _subscription(context)));
}

@widgetbook.UseCase(name: 'Default', type: SubscriptionSummaryCard, path: _path)
Widget subscriptionSummaryCardUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 400,
      child: SubscriptionSummaryCard(
        summary: (
          activeCount: context.knobs.int.slider(
            label: 'Active',
            initialValue: 4,
            max: 20,
          ),
          totalSpent: context.knobs.double.input(
            label: 'Total spent',
            initialValue: 184500,
          ),
          monthlyCost: context.knobs.double.input(
            label: 'Monthly cost',
            initialValue: 21490,
          ),
        ),
      ),
    ),
  );
}
