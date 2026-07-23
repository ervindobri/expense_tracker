enum CategoryType { expense, income }

class Category {
  final int id;
  final String name;
  final CategoryType type;

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
}

class Entry {
  final double amount;
  final int category;
  final DateTime addedDate;

  Entry({
    required this.amount,
    required this.addedDate,
    required this.category,
  });
  factory Entry.from(Map<String, dynamic> e) {
    return Entry(
      amount: e['amount'] ?? 0.0,
      // the API serializes the store as its integer primary key
      category:
          e['category'] ?? 0,
      addedDate: DateTime.parse(e['added_date'] ?? ''),
    );
  }
}

class EntriesList {
  final int total;
  final List<Entry> items;

  EntriesList({required this.total, required this.items});

  factory EntriesList.from(Map<String, dynamic> json) {
    return EntriesList(
      total: json['query']['results_count'],
      items: (json['products'] as List<dynamic>)
          .map((e) => Entry.from(e))
          .toList(),
    );
  }
}

class Balance {
  final double totalAmount;
  final double expenses;
  final double incomes;

  Balance({
    required this.totalAmount,
    required this.expenses,
    required this.incomes,
  });
  double get savings => incomes - expenses;
}
