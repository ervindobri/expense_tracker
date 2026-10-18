import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:frontend/core/extensions/date_time.dart';

class Entry {
  Entry({
    required this.id,
    required this.amount,
    required this.addedDate,
    required this.category,
    required this.createdDate,
    this.notes = '',
    this.subscription,
  });
  factory Entry.from(Map<String, dynamic> e) {
    final category = e['category'];
    return Entry(
      id: e['id'] ?? 0,
      amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
      // the API may send the category as its id or as the nested object
      category: category is Map ? category['id'] ?? 0 : category ?? 0,
      addedDate: DateTime.parse(e['added_date'] ?? '').ignoringTimezone,
      notes: e['notes'] ?? '',
      createdDate: DateTime.parse(e['created_date'] ?? '').ignoringTimezone,
      subscription: e['subscription'] as int?,
    );
  }
  final int id;
  final double amount;
  final int category;
  final DateTime addedDate;
  final DateTime createdDate;
  final String notes;

  /// Id of the subscription this entry pays for, if any.
  final int? subscription;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'added_date': addedDate.toIso8601String(),
      'notes': notes,
      'created_date': DateTime.now().toIso8601String(),
      'subscription': subscription,
    };
  }

  /// [subscription] is a getter so `null` can be passed to unlink the entry.
  Entry copyWith({
    int? id,
    double? amount,
    String? notes,
    int? Function()? subscription,
  }) {
    return Entry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      addedDate: addedDate,
      category: category,
      notes: notes ?? this.notes,
      createdDate: createdDate,
      subscription: subscription != null ? subscription() : this.subscription,
    );
  }
}

class EntriesList {
  EntriesList({required this.total, required this.items});

  factory EntriesList.from(Map<String, dynamic> json) {
    return EntriesList(
      total: json['query']['results_count'],
      items: (json['products'] as List<dynamic>)
          .map((e) => Entry.from(e))
          .toList(),
    );
  }
  final int total;
  final List<Entry> items;

  DateTime? get lastCreated => items.isEmpty
      ? null
      : items
            .reduce((a, b) => a.createdDate.isAfter(b.createdDate) ? a : b)
            .addedDate;

  SplayTreeMap<DateTime, List<Entry>> get grouped {
    final groupedItems = groupBy(items, (Entry e) {
      return DateTime(
        e.createdDate.year,
        e.createdDate.month,
        e.createdDate.day,
      );
    });
    return SplayTreeMap<DateTime, List<Entry>>.from(
      groupedItems,
      (a, b) => b.compareTo(a),
    );
  }
}

class Balance {
  Balance({
    required this.totalAmount,
    required this.expenses,
    required this.incomes,
  });
  final double totalAmount;
  final double expenses;
  final double incomes;
  double get savings => incomes - expenses;
}
