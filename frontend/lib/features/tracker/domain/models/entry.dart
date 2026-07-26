import 'package:frontend/core/extensions/date_time.dart';

enum CategoryType { expense, income }


extension CategoryTypeExt on CategoryType {
  String get displayName => switch (this) {
    CategoryType.expense => '🛍️ Expenses',
    CategoryType.income => '💰 Incomes',
  };
}

class Category {

  Category({required this.name, required this.type, required this.id});

  factory Category.from(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['category_type'] == 'E'
          ? CategoryType.expense
          : CategoryType.income,
    );
  }
  final int id;
  final String name;
  final CategoryType type;
}

class Entry {

  Entry({
    required this.id,
    required this.amount,
    required this.addedDate,
    required this.category,
  });
  factory Entry.from(Map<String, dynamic> e) {
    return Entry(
      id: e['id'] ?? 0,
      amount: e['amount'] ?? 0.0,
      // the API serializes the store as its integer primary key
      category: e['category'] ?? 0,
      addedDate: DateTime.parse(e['added_date'] ?? '').ignoringTimezone,
    );
  }
  final int id;
  final double amount;
  final int category;
  final DateTime addedDate;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'added_date': addedDate.toIso8601String(),
    };
  }

  Entry copyWith({required int id}) {
    return Entry(id: id, amount: amount, addedDate: addedDate, category: category,);
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
