
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

  bool get isExpense => type == CategoryType.expense;
}