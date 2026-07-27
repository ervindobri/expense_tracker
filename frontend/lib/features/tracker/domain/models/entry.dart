import 'package:frontend/core/extensions/date_time.dart';

class Entry {

  Entry({
    required this.id,
    required this.amount,
    required this.addedDate,
    required this.category,
    this.notes = '',
  });
  factory Entry.from(Map<String, dynamic> e) {
    return Entry(
      id: e['id'] ?? 0,
      amount: e['amount'] ?? 0.0,
      // the API serializes the store as its integer primary key
      category: e['category'] ?? 0,
      addedDate: DateTime.parse(e['added_date'] ?? '').ignoringTimezone,
      notes: e['notes'] ?? '',
    );
  }
  final int id;
  final double amount;
  final int category;
  final DateTime addedDate;
  final String notes;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'added_date': addedDate.toIso8601String(),
      'notes': notes,
    };
  }

  Entry copyWith({int? id, String? notes}) {
    return Entry(
      id: id ?? this.id,
      amount: amount,
      addedDate: addedDate,
      category: category,
      notes: notes ?? this.notes,
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
