import 'package:flutter/material.dart';

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


extension CategoryExt on Category {
  Color get color => switch (id) {
    1 => Colors.orange,
    2 => const Color.fromARGB(255, 255, 105, 59), //groceries
    3 => Colors.deepPurple,
    4 => Colors.green,
    5 => const Color.fromARGB(255, 176, 144, 39), //drinking out
    6 => Colors.blue,
    7 => Colors.deepOrange,
    8 => Colors.lightBlue,
    9 => Colors.lightGreen,
    10 => const Color.fromARGB(255, 233, 30, 230), //transport
    11 => Colors.amber, //subs
    12 => Colors.blueGrey,
    13 => Colors.cyan,
    14 => Colors.teal,
    15 => const Color.fromARGB(255, 49, 88, 124), //Salary
    16 => Colors.blueGrey, // gifts
    17 => Colors.lightGreen, //others
    18 => Colors.green, //cafeteria
    _ => Colors.white,
  };

  String get emoji => switch (id) {
    1 => '🏚️', // rent & bills
    2 => '🍅', // groceries
    3 => '📦', // supplies
    4 => '🍝', // dining out
    5 => '🍻', // drinking out
    6 => '🖥️', //Electronics & digital
    7 => '❤️‍🩹', //Health & medicine
    8 => '👕', //FAshion
    9 => '👙', // Vacation
    10 => '🚋', //Transport
    11 => '🔁', // Subscriptions
    12 => '💝', // Gifts & dates
    13 => '🎥', // Entertainment
    14 => '❔', // Others
    15 => '💰', //Salary
    16 => '🎁', // gifts
    17 => '❔', //others
    18 => '☕', //cafeteria
    _ => '$this',
  };
}
