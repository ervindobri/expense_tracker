import 'package:frontend/core/state/currency_provider.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscriptions_provider.g.dart';

/// How far ahead the "renewing soon" row looks.
const kRenewingSoonDays = 14;

@riverpod
Future<List<Subscription>> subscriptions(Ref ref) {
  return ref.watch(subscriptionRepositoryProvider).getSubscriptions();
}

/// Active subscriptions, soonest renewal first.
@riverpod
List<Subscription> activeSubscriptions(Ref ref) {
  final all = ref.watch(subscriptionsProvider).value ?? const [];
  return sortByRenewal(all.where((s) => s.isActive));
}

@riverpod
List<Subscription> inactiveSubscriptions(Ref ref) {
  final all = ref.watch(subscriptionsProvider).value ?? const [];
  return all.where((s) => !s.isActive).toList();
}

@riverpod
List<Subscription> renewingSoon(Ref ref) {
  return ref
      .watch(activeSubscriptionsProvider)
      .where((s) => s.daysUntilRenewal() <= kRenewingSoonDays)
      .toList();
}

typedef SubscriptionSummary = ({
  int activeCount,
  double totalSpent,
  double monthlyCost,
});

@riverpod
SubscriptionSummary subscriptionSummary(Ref ref) {
  final all = ref.watch(subscriptionsProvider).value ?? const [];
  final hufRates = {
    for (final c in all.map((s) => s.currency).toSet())
      c: ref.watch(toHufRateProvider(c)).value ?? c.fallbackToHuf,
  };
  return summarize(all, hufRates: hufRates);
}

List<Subscription> sortByRenewal(Iterable<Subscription> subscriptions) {
  final now = DateTime.now();
  return subscriptions.toList()..sort(
    (a, b) => a.nextRenewal(now: now).compareTo(b.nextRenewal(now: now)),
  );
}

/// Spending counts every subscription, removed ones included, since that
/// money was still spent; the count and monthly cost only cover active ones.
/// [hufRates] converts prices in other currencies; the result is in HUF.
SubscriptionSummary summarize(
  List<Subscription> subscriptions, {
  Map<Currency, double> hufRates = const {},
}) {
  final active = subscriptions.where((s) => s.isActive);
  return (
    activeCount: active.length,
    totalSpent: subscriptions.fold(0.0, (sum, s) => sum + s.totalSpent),
    monthlyCost: active.fold(
      0.0,
      (sum, s) =>
          sum +
          s.monthlyCost *
              (s.currency == Currency.huf
                  ? 1
                  : hufRates[s.currency] ?? s.currency.fallbackToHuf),
    ),
  );
}
