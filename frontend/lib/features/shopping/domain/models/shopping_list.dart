import 'dart:typed_data';

import 'package:frontend/features/settings/domain/currency.dart';

/// Most photos a single item can hold; the server enforces the same.
const maxItemImages = 10;

/// Photo attached to an item's description, stored on the server.
class ShoppingImage {
  const ShoppingImage({required this.id, required this.url});

  factory ShoppingImage.from(Map<String, dynamic> json) =>
      ShoppingImage(id: json['id'] ?? 0, url: json['url'] ?? '');

  final int id;

  /// Absolute address to load it from as a network image.
  final String url;

  @override
  bool operator ==(Object other) =>
      other is ShoppingImage && other.id == id && other.url == url;

  @override
  int get hashCode => Object.hash(id, url);
}

/// Photo picked on this device, not uploaded yet.
class ImageUpload {
  const ImageUpload({required this.bytes, required this.filename});

  final Uint8List bytes;

  /// Name to upload it as; always ends in an image extension the server
  /// accepts.
  final String filename;

  static const _extensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
  static const _byMimeType = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/gif': 'gif',
    'image/webp': 'webp',
  };

  /// Keeps [name] when it has a known image extension, otherwise names it
  /// after [mimeType] (JPEG when unknown, which pickers re-encode to).
  static String uploadName(String name, {String? mimeType}) {
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (_extensions.contains(extension)) {
      return name;
    }
    final base = (dot < 0 ? name : name.substring(0, dot)).trim();
    return '${base.isEmpty ? 'photo' : base}.${_byMimeType[mimeType] ?? 'jpg'}';
  }
}

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
    this.position = 0,
    this.images = const [],
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
      position: json['position'] ?? 0,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => ShoppingImage.from(e as Map<String, dynamic>))
          .toList(),
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

  /// Order within its list, set by dragging; lowest first.
  final int position;

  /// Photos shown with [description], oldest first. Changed through their
  /// own endpoint, so not part of [toJson].
  final List<ShoppingImage> images;

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
    int? position,
    List<ShoppingImage>? images,
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
      position: position ?? this.position,
      images: images ?? this.images,
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
    ).sortedByPosition();
  }

  /// Copy with [items] ordered by [ShoppingItem.position], ties keeping
  /// their current order.
  ShoppingList sortedByPosition() {
    final indexed = items.indexed.toList()
      ..sort((a, b) {
        final byPosition = a.$2.position.compareTo(b.$2.position);
        return byPosition != 0 ? byPosition : a.$1.compareTo(b.$1);
      });
    return copyWith(items: [for (final (_, item) in indexed) item]);
  }

  /// Copy with [itemIds] first, in that order, then the rest as they were;
  /// positions are renumbered to match.
  ShoppingList reordered(List<int> itemIds) {
    final byId = {for (final i in items) i.id: i};
    final ordered = [
      for (final id in itemIds) ?byId[id],
      ...items.where((i) => !itemIds.contains(i.id)),
    ];
    return copyWith(
      items: [
        for (final (position, item) in ordered.indexed)
          item.copyWith(position: position),
      ],
    );
  }

  final int id;
  final String name;
  final List<ShoppingItem> items;

  /// Still to buy, in the list's order.
  List<ShoppingItem> get toBuy => items.where((i) => !i.isBought).toList();

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
