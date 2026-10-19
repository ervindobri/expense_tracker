import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';

enum SubscriptionPeriod { daily, weekly, biweekly, monthly, quarterly, yearly }

extension SubscriptionPeriodExt on SubscriptionPeriod {
  /// Single-letter code the API stores.
  String get apiValue => switch (this) {
    SubscriptionPeriod.daily => 'D',
    SubscriptionPeriod.weekly => 'W',
    SubscriptionPeriod.biweekly => 'B',
    SubscriptionPeriod.monthly => 'M',
    SubscriptionPeriod.quarterly => 'Q',
    SubscriptionPeriod.yearly => 'Y',
  };

  static SubscriptionPeriod fromApi(String? value) =>
      SubscriptionPeriod.values.firstWhere(
        (p) => p.apiValue == value,
        orElse: () => SubscriptionPeriod.monthly,
      );

  String get label => switch (this) {
    SubscriptionPeriod.daily => LocaleKeys.period_daily,
    SubscriptionPeriod.weekly => LocaleKeys.period_weekly,
    SubscriptionPeriod.biweekly => LocaleKeys.period_biweekly,
    SubscriptionPeriod.monthly => LocaleKeys.period_monthly,
    SubscriptionPeriod.quarterly => LocaleKeys.period_quarterly,
    SubscriptionPeriod.yearly => LocaleKeys.period_yearly,
  }.tr();

  /// How many periods fit in an average month, to compare costs.
  double get perMonth => switch (this) {
    SubscriptionPeriod.daily => 365 / 12,
    SubscriptionPeriod.weekly => 52 / 12,
    SubscriptionPeriod.biweekly => 26 / 12,
    SubscriptionPeriod.monthly => 1,
    SubscriptionPeriod.quarterly => 1 / 3,
    SubscriptionPeriod.yearly => 1 / 12,
  };

  /// Length of the period in days, or null for calendar-month based ones.
  int? get _days => switch (this) {
    SubscriptionPeriod.daily => 1,
    SubscriptionPeriod.weekly => 7,
    SubscriptionPeriod.biweekly => 14,
    _ => null,
  };

  int get _months => switch (this) {
    SubscriptionPeriod.quarterly => 3,
    SubscriptionPeriod.yearly => 12,
    _ => 1,
  };

  /// [anchor] moved forward by [count] periods. Month based periods keep the
  /// anchor's day, clamped to the month's length (Jan 31 -> Feb 28).
  DateTime advance(DateTime anchor, int count) {
    // UTC so day arithmetic is not skewed by DST changes
    final start = DateTime.utc(anchor.year, anchor.month, anchor.day);
    final days = _days;
    if (days != null) {
      final d = start.add(Duration(days: days * count));
      return DateTime(d.year, d.month, d.day);
    }
    // DateTime rolls month overflow (or underflow) into the year
    final month = DateTime.utc(start.year, start.month + _months * count);
    final lastDay = DateTime.utc(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, min(start.day, lastDay));
  }
}

class Subscription {
  Subscription({
    required this.id,
    required this.name,
    required this.period,
    required this.createdDate,
    this.amount = 0,
    this.currency = Currency.huf,
    this.isActive = true,
    this.entries = const [],
    this.totalSpent = 0,
  });

  factory Subscription.from(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: CurrencyCode.fromCode(json['currency']),
      period: SubscriptionPeriodExt.fromApi(json['period']),
      isActive: json['is_active'] ?? true,
      // stored in UTC
      createdDate: DateTime.parse(json['created_date'] ?? '').toLocal(),
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => Entry.from(e))
          .toList(),
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
    );
  }

  final int id;
  final String name;

  /// Expected cost per period in [currency]; actual spending comes from
  /// [entries], which are always HUF.
  final double amount;
  final Currency currency;
  final SubscriptionPeriod period;
  final bool isActive;
  final DateTime createdDate;

  /// Linked entries, newest first.
  final List<Entry> entries;
  final double totalSpent;

  /// Monthly cost in [currency].
  double get monthlyCost => amount * period.perMonth;

  DateTime? get lastPayment => entries.firstOrNull?.addedDate;

  /// First renewal on or after [now]'s day, counted in whole periods from
  /// [createdDate].
  DateTime nextRenewal({DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final anchor = DateTime.utc(
      createdDate.year,
      createdDate.month,
      createdDate.day,
    );
    // Jump close to today instead of stepping one period at a time, then
    // walk forward to the first date that is not in the past.
    final days = period._days;
    var count = days != null
        ? todayUtc.difference(anchor).inDays ~/ days
        : ((todayUtc.year - anchor.year) * 12 +
                  todayUtc.month -
                  anchor.month) ~/
              period._months;
    count = max(count, 1);
    var candidate = period.advance(anchor, count);
    while (DateTime.utc(
      candidate.year,
      candidate.month,
      candidate.day,
    ).isBefore(todayUtc)) {
      candidate = period.advance(anchor, ++count);
    }
    return candidate;
  }

  /// Whole days until [nextRenewal]; 0 means it renews today.
  int daysUntilRenewal({DateTime? now}) {
    final today = now ?? DateTime.now();
    final next = nextRenewal(now: today);
    return DateTime.utc(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'currency': currency.code,
      'period': period.apiValue,
      'is_active': isActive,
      'created_date': createdDate.toUtc().toIso8601String(),
    };
  }

  Subscription copyWith({
    String? name,
    double? amount,
    Currency? currency,
    SubscriptionPeriod? period,
    bool? isActive,
    DateTime? createdDate,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      period: period ?? this.period,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      entries: entries,
      totalSpent: totalSpent,
    );
  }
}
