import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/presentation/state/subscriptions_provider.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';

Subscription _sub(
  SubscriptionPeriod period,
  DateTime created, {
  int id = 1,
  double amount = 0,
  bool isActive = true,
  double totalSpent = 0,
}) => Subscription(
  id: id,
  name: 'Phone',
  period: period,
  createdDate: created,
  amount: amount,
  isActive: isActive,
  totalSpent: totalSpent,
);

void main() {
  group('nextRenewal', () {
    test('a new subscription renews one period after creation', () {
      final created = DateTime(2026, 10, 18, 14, 30);
      final now = DateTime(2026, 10, 18, 20);
      expect(
        _sub(SubscriptionPeriod.daily, created).nextRenewal(now: now),
        DateTime(2026, 10, 19),
      );
      expect(
        _sub(SubscriptionPeriod.weekly, created).nextRenewal(now: now),
        DateTime(2026, 10, 25),
      );
      expect(
        _sub(SubscriptionPeriod.biweekly, created).nextRenewal(now: now),
        DateTime(2026, 11, 1),
      );
      expect(
        _sub(SubscriptionPeriod.monthly, created).nextRenewal(now: now),
        DateTime(2026, 11, 18),
      );
      expect(
        _sub(SubscriptionPeriod.quarterly, created).nextRenewal(now: now),
        DateTime(2027, 1, 18),
      );
      expect(
        _sub(SubscriptionPeriod.yearly, created).nextRenewal(now: now),
        DateTime(2027, 10, 18),
      );
    });

    test('skips renewals that already passed', () {
      final sub = _sub(SubscriptionPeriod.monthly, DateTime(2026, 1, 5));
      expect(
        sub.nextRenewal(now: DateTime(2026, 10, 6)),
        DateTime(2026, 11, 5),
      );
      expect(
        _sub(
          SubscriptionPeriod.weekly,
          DateTime(2026, 1, 1),
        ).nextRenewal(now: DateTime(2026, 10, 18)),
        DateTime(2026, 10, 22),
      );
    });

    test('a renewal falling on today counts as today', () {
      final sub = _sub(SubscriptionPeriod.monthly, DateTime(2026, 1, 5));
      final now = DateTime(2026, 10, 5, 23, 59);
      expect(sub.nextRenewal(now: now), DateTime(2026, 10, 5));
      expect(sub.daysUntilRenewal(now: now), 0);
    });

    test('clamps month-end anchors without drifting', () {
      final sub = _sub(SubscriptionPeriod.monthly, DateTime(2026, 1, 31));
      expect(sub.nextRenewal(now: DateTime(2026, 2, 1)), DateTime(2026, 2, 28));
      // back to the 31st once the month allows it
      expect(sub.nextRenewal(now: DateTime(2026, 3, 1)), DateTime(2026, 3, 31));
      expect(sub.nextRenewal(now: DateTime(2026, 4, 1)), DateTime(2026, 4, 30));
    });

    test('handles leap days for yearly subscriptions', () {
      final sub = _sub(SubscriptionPeriod.yearly, DateTime(2024, 2, 29));
      expect(sub.nextRenewal(now: DateTime(2025, 1, 1)), DateTime(2025, 2, 28));
      expect(sub.nextRenewal(now: DateTime(2027, 6, 1)), DateTime(2028, 2, 29));
    });

    test('advance also steps backwards across a year boundary', () {
      expect(
        SubscriptionPeriod.monthly.advance(DateTime(2026, 1, 31), -1),
        DateTime(2025, 12, 31),
      );
      expect(
        SubscriptionPeriod.quarterly.advance(DateTime(2026, 2, 10), -1),
        DateTime(2025, 11, 10),
      );
    });

    test('counts days across a DST change', () {
      // Europe switches back to winter time on the last Sunday of October.
      final sub = _sub(SubscriptionPeriod.weekly, DateTime(2026, 10, 20));
      expect(sub.daysUntilRenewal(now: DateTime(2026, 10, 24)), 3);
    });
  });

  group('Subscription.from', () {
    test('parses the API payload with linked entries', () {
      final sub = Subscription.from({
        'id': 3,
        'name': 'Netflix',
        'amount': 4290,
        'period': 'Q',
        'is_active': false,
        'created_date': '2026-10-01T10:00:00Z',
        'total_spent': 8580,
        'entries': [
          {
            'id': 9,
            'amount': 4290,
            'category': {'id': 11, 'name': 'Subscriptions'},
            'added_date': '2026-10-01T10:00:00',
            'created_date': '2026-10-01T10:00:00Z',
            'notes': '',
            'subscription': 3,
          },
        ],
      });

      expect(sub.id, 3);
      expect(sub.amount, 4290.0);
      expect(sub.currency, Currency.huf); // missing -> HUF
      expect(sub.period, SubscriptionPeriod.quarterly);
      expect(sub.isActive, isFalse);
      expect(sub.totalSpent, 8580.0);
      expect(sub.entries.single.category, 11);
      expect(sub.entries.single.subscription, 3);
      expect(sub.lastPayment, DateTime(2026, 10, 1, 10));
    });

    test('round-trips the writable fields', () {
      final created = DateTime(2026, 9, 5, 14, 30);
      final json = _sub(
        SubscriptionPeriod.biweekly,
        created,
        amount: 1200,
      ).toJson();
      expect(json, {
        'name': 'Phone',
        'amount': 1200.0,
        'currency': 'HUF',
        'period': 'B',
        'is_active': true,
        'created_date': created.toUtc().toIso8601String(),
      });
      // the API sends it back in UTC; it reads as the same local moment
      final parsed = Subscription.from({
        ...json,
        'id': 1,
        'created_date': json['created_date'],
      });
      expect(parsed.createdDate, created);
    });
  });

  test('Entry.copyWith can unlink a subscription', () {
    final entry = Entry(
      id: 1,
      amount: 10,
      addedDate: DateTime(2026),
      category: 1,
      createdDate: DateTime(2026),
      subscription: 4,
    );
    expect(entry.copyWith(amount: 20).subscription, 4);
    expect(entry.copyWith(subscription: () => null).subscription, isNull);
  });

  group('summarize', () {
    test('counts active ones but includes removed spending', () {
      final summary = summarize([
        _sub(
          SubscriptionPeriod.monthly,
          DateTime(2026),
          amount: 5000,
          totalSpent: 50000,
        ),
        _sub(
          SubscriptionPeriod.yearly,
          DateTime(2026),
          amount: 12000,
          totalSpent: 12000,
        ),
        _sub(
          SubscriptionPeriod.monthly,
          DateTime(2026),
          amount: 3000,
          isActive: false,
          totalSpent: 9000,
        ),
      ]);
      expect(summary.activeCount, 2);
      expect(summary.totalSpent, 71000);
      expect(summary.monthlyCost, 6000);
    });

    test('converts foreign prices to HUF for the monthly cost', () {
      final summary = summarize(
        [
          _sub(SubscriptionPeriod.monthly, DateTime(2026), amount: 3000),
          Subscription(
            id: 2,
            name: 'Spotify',
            period: SubscriptionPeriod.monthly,
            createdDate: DateTime(2026),
            amount: 10,
            currency: Currency.eur,
          ),
        ],
        hufRates: {Currency.eur: 400},
      );
      expect(summary.monthlyCost, 7000);
    });
  });

  test('parses and sends the price currency', () {
    final sub = Subscription.from({
      'id': 1,
      'name': 'Spotify',
      'amount': 10.99,
      'currency': 'EUR',
      'period': 'M',
      'created_date': '2026-10-01T10:00:00Z',
    });
    expect(sub.currency, Currency.eur);
    expect(sub.copyWith(currency: Currency.usd).toJson()['currency'], 'USD');
  });

  test('fallback rates convert in both directions', () {
    expect(Currency.huf.fallbackToHuf, 1);
    expect(Currency.eur.fallbackToHuf, closeTo(362.3, 0.1));
  });
}
