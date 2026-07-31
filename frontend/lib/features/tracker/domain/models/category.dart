import 'dart:ui';

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
    2 => Colors.yellow,
    3 => Colors.deepPurple,
    4 => Colors.green,
    5 => Colors.purple,
    6 => Colors.blue,
    7 => Colors.deepOrange,
    8 => Colors.lightBlue,
    9 => Colors.lightGreen,
    10 => Colors.pink,
    11 => Colors.amber,
    12 => Colors.blueGrey,
    13 => Colors.cyan,
    14 => Colors.teal,
    15 => Colors.greenAccent, //Salary
    16 => Colors.blueGrey, // gifts
    17 => Colors.lightGreen, //others
    18 => Colors.green,
    19 => Colors.green,
    _ => Colors.white,
  };
}
