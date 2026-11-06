import 'package:frontend/features/settings/domain/currency.dart';

/// Something to buy, checked off once bought.
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.description = '',
    this.expectedPrice = 0,
    this.currency = Currency.huf,
    this.buyingGoal,
    this.isBought = false,
  });

  factory ShoppingItem.from(Map<String, dynamic> json) {
    final goal = json['buying_goal'] as String?;
    return ShoppingItem(
      id: json['id'] ?? 0,
      listId: json['shopping_list'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      expectedPrice: (json['expected_price'] as num?)?.toDouble() ?? 0,
      currency: CurrencyCode.fromCode(json['currency']),
      // a plain date, so no timezone conversion
      buyingGoal: goal == null ? null : DateTime.parse(goal),
      isBought: json['is_bought'] ?? false,
    );
  }

  final int id;
  final int listId;
  final String name;

  /// Free-form notes: product details, links to where to buy it.
  final String description;

  /// Web links found in [description], in order.
  List<Uri> get links => extractLinks(description);

  /// Estimate in [currency]; 0 when unknown.
  final double expectedPrice;
  final Currency currency;

  /// Day it should be bought by, if any.
  final DateTime? buyingGoal;
  final bool isBought;

  /// Whole days until [buyingGoal]; negative once it has passed.
  int? daysUntilGoal({DateTime? now}) {
    final goal = buyingGoal;
    if (goal == null) {
      return null;
    }
    final today = now ?? DateTime.now();
    return DateTime.utc(
      goal.year,
      goal.month,
      goal.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }

  bool isOverdue({DateTime? now}) =>
      !isBought && (daysUntilGoal(now: now) ?? 0) < 0;

  Map<String, dynamic> toJson() {
    final goal = buyingGoal;
    return {
      'shopping_list': listId,
      'name': name,
      'description': description,
      'expected_price': expectedPrice,
      'currency': currency.code,
      'buying_goal': goal == null
          ? null
          : '${goal.year.toString().padLeft(4, '0')}-'
                '${goal.month.toString().padLeft(2, '0')}-'
                '${goal.day.toString().padLeft(2, '0')}',
      'is_bought': isBought,
    };
  }

  ShoppingItem copyWith({
    String? name,
    String? description,
    double? expectedPrice,
    Currency? currency,
    DateTime? Function()? buyingGoal,
    bool? isBought,
  }) {
    return ShoppingItem(
      id: id,
      listId: listId,
      name: name ?? this.name,
      description: description ?? this.description,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      currency: currency ?? this.currency,
      buyingGoal: buyingGoal != null ? buyingGoal() : this.buyingGoal,
      isBought: isBought ?? this.isBought,
    );
  }
}

/// Named checklist of things to buy (groceries, house...).
class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    this.items = const [],
  });

  factory ShoppingList.from(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ShoppingItem.from(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final List<ShoppingItem> items;

  /// Still to buy, soonest goal first, items without a goal last.
  List<ShoppingItem> get toBuy => sortItems(items.where((i) => !i.isBought));

  List<ShoppingItem> get bought => items.where((i) => i.isBought).toList();

  Map<String, dynamic> toJson() => {'name': name};

  ShoppingList copyWith({String? name, List<ShoppingItem>? items}) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

/// Soonest [ShoppingItem.buyingGoal] first, items without one last; stable
/// otherwise so the server's order (oldest first) is kept.
List<ShoppingItem> sortItems(Iterable<ShoppingItem> items) {
  final list = items.toList();
  final indexed = {for (var i = 0; i < list.length; i++) list[i]: i};
  return list..sort((a, b) {
    final ga = a.buyingGoal;
    final gb = b.buyingGoal;
    if (ga != null && gb != null && ga != gb) {
      return ga.compareTo(gb);
    }
    if ((ga == null) != (gb == null)) {
      return ga == null ? 1 : -1;
    }
    return indexed[a]!.compareTo(indexed[b]!);
  });
}

final _linkPattern = RegExp(
  r'(?:https?://|www\.)[^\s<>"]+',
  caseSensitive: false,
);

/// Web links in [text]: `http(s)://` and bare `www.` addresses, without
/// trailing punctuation, duplicates dropped.
List<Uri> extractLinks(String text) {
  final links = <Uri>[];
  for (final match in _linkPattern.allMatches(text)) {
    final raw = match.group(0)!.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
    final uri = Uri.tryParse(
      raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw,
    );
    if (uri != null && uri.host.isNotEmpty && !links.contains(uri)) {
      links.add(uri);
    }
  }
  return links;
}

/// Short label for [uri]: its host without `www.`, e.g. "ikea.com".
String linkLabel(Uri uri) => uri.host.replaceFirst(RegExp('^www\\.'), '');
