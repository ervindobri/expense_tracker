import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/presentation/widgets/paste/pasted_images.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_links.dart';

void main() {
  group('ShoppingItem', () {
    test('parses the API shape', () {
      final item = ShoppingItem.from({
        'id': 3,
        'shopping_list': 1,
        'name': 'Sofa',
        'expected_price': 250000,
        'currency': 'EUR',
        'buying_goal': '2026-12-24',
        'is_bought': true,
      });
      expect(item.id, 3);
      expect(item.listId, 1);
      expect(item.expectedPrice, 250000.0);
      expect(item.currency, Currency.eur);
      expect(item.buyingGoal, DateTime(2026, 12, 24));
      expect(item.isBought, isTrue);
    });

    test('defaults missing optional fields', () {
      final item = ShoppingItem.from({
        'id': 1,
        'shopping_list': 1,
        'name': 'Milk',
        'buying_goal': null,
      });
      expect(item.expectedPrice, 0);
      expect(item.currency, Currency.huf);
      expect(item.buyingGoal, isNull);
      expect(item.isBought, isFalse);
    });

    test('sends the goal as a plain date', () {
      final json = ShoppingItem(
        id: 1,
        listId: 2,
        name: 'Lamp',
        buyingGoal: DateTime(2027, 3, 5),
      ).toJson();
      expect(json['buying_goal'], '2027-03-05');
      expect(json['shopping_list'], 2);
      expect(
        const ShoppingItem(
          id: 1,
          listId: 2,
          name: 'Lamp',
        ).toJson()['buying_goal'],
        isNull,
      );
    });

    test('copyWith can clear the goal', () {
      final item = ShoppingItem(
        id: 1,
        listId: 1,
        name: 'Lamp',
        buyingGoal: DateTime(2027),
      );
      expect(item.copyWith(name: 'x').buyingGoal, DateTime(2027));
      expect(item.copyWith(buyingGoal: () => null).buyingGoal, isNull);
    });

    test('counts days until the goal and flags overdue unbought items', () {
      final now = DateTime(2026, 11, 6, 22, 30);
      ShoppingItem withGoal(DateTime goal, {bool bought = false}) =>
          ShoppingItem(
            id: 1,
            listId: 1,
            name: 'x',
            buyingGoal: goal,
            isBought: bought,
          );
      expect(withGoal(DateTime(2026, 11, 6)).daysUntilGoal(now: now), 0);
      expect(withGoal(DateTime(2026, 11, 7)).daysUntilGoal(now: now), 1);
      expect(withGoal(DateTime(2026, 11, 4)).daysUntilGoal(now: now), -2);
      expect(withGoal(DateTime(2026, 11, 4)).isOverdue(now: now), isTrue);
      expect(
        withGoal(DateTime(2026, 11, 4), bought: true).isOverdue(now: now),
        isFalse,
      );
      expect(withGoal(DateTime(2026, 11, 6)).isOverdue(now: now), isFalse);
      expect(
        const ShoppingItem(id: 1, listId: 1, name: 'x').isOverdue(now: now),
        isFalse,
      );
    });
  });

  group('ShoppingList', () {
    ShoppingItem item(int id, {int position = 0, bool bought = false}) =>
        ShoppingItem(
          id: id,
          listId: 1,
          name: '$id',
          position: position,
          isBought: bought,
          // goals don't affect the order any more
          buyingGoal: DateTime(2030 - id),
        );

    test('keeps items by position, split into to buy and bought', () {
      final list = ShoppingList.from({
        'id': 1,
        'name': 'House',
        'items': [
          {'id': 3, 'shopping_list': 1, 'name': 'C', 'position': 2},
          {'id': 1, 'shopping_list': 1, 'name': 'A', 'position': 0},
          {
            'id': 2,
            'shopping_list': 1,
            'name': 'B',
            'position': 1,
            'is_bought': true,
          },
          {
            'id': 4,
            'shopping_list': 1,
            'name': 'D',
            'position': 3,
            'buying_goal': '2026-01-01',
          },
        ],
      });
      expect(list.items.map((i) => i.name), ['A', 'B', 'C', 'D']);
      expect(list.toBuy.map((i) => i.name), ['A', 'C', 'D']);
      expect(list.bought.map((i) => i.name), ['B']);
    });

    test('sorting by position keeps ties in their current order', () {
      final list = ShoppingList(
        id: 1,
        name: 'x',
        items: [item(1, position: 1), item(2), item(3, position: 1)],
      ).sortedByPosition();
      expect(list.items.map((i) => i.id), [2, 1, 3]);
    });

    test('reordered puts the given ids first and renumbers positions', () {
      final list = ShoppingList(
        id: 1,
        name: 'x',
        items: [
          item(1),
          item(2, position: 1),
          item(3, position: 2, bought: true),
          item(4, position: 3),
        ],
      ).reordered([4, 1]);
      expect(list.items.map((i) => i.id), [4, 1, 2, 3]);
      expect(list.items.map((i) => i.position), [0, 1, 2, 3]);
      // other fields survive the move
      expect(list.items[3].isBought, isTrue);
    });

    test('position survives copyWith and toggling', () {
      final moved = item(1, position: 5).copyWith(isBought: true);
      expect(moved.position, 5);
      expect(ShoppingItem.from({'id': 1, 'shopping_list': 1}).position, 0);
    });
  });

  group('description', () {
    test('round-trips through the API shape and defaults to empty', () {
      final item = ShoppingItem.from({
        'id': 1,
        'shopping_list': 1,
        'name': 'Sofa',
        'description': 'Grey, 3 seats',
      });
      expect(item.description, 'Grey, 3 seats');
      expect(item.toJson()['description'], 'Grey, 3 seats');
      expect(item.copyWith(description: 'Blue').description, 'Blue');
      expect(ShoppingItem.from({'id': 1, 'shopping_list': 1}).description, '');
    });

    test('finds http(s) and www links without trailing punctuation', () {
      final links = extractLinks(
        'Sofa (https://www.ikea.com/hu/hu/p/sofa-123/), or '
        'www.jysk.hu/sofa. Also https://www.ikea.com/hu/hu/p/sofa-123/ again',
      );
      expect(links.map((l) => l.toString()), [
        'https://www.ikea.com/hu/hu/p/sofa-123/',
        'https://www.jysk.hu/sofa',
      ]);
      expect(links.map(linkLabel), ['ikea.com', 'jysk.hu']);
      expect(extractLinks('no links here, just a.b'), isEmpty);
    });

    test('preview is one line with links shortened to their site', () {
      expect(
        descriptionPreview(
          'Grey, 3 seats\n\nhttps://www.ikea.com/hu/hu/p/sofa-123/',
        ),
        'Grey, 3 seats · ikea.com',
      );
      expect(descriptionPreview(''), '');
    });
  });

  group('images', () {
    test('parse from the API shape and default to none', () {
      final item = ShoppingItem.from({
        'id': 1,
        'shopping_list': 1,
        'name': 'Sofa',
        'images': [
          {'id': 7, 'item': 1, 'url': 'https://host/media/shopping/a.jpg'},
        ],
      });
      expect(item.images, [
        const ShoppingImage(id: 7, url: 'https://host/media/shopping/a.jpg'),
      ]);
      expect(ShoppingItem.from({'id': 2, 'shopping_list': 1}).images, isEmpty);
    });

    test('survive copyWith and are not sent with the item', () {
      const image = ShoppingImage(id: 7, url: 'https://host/a.jpg');
      const item = ShoppingItem(
        id: 1,
        listId: 1,
        name: 'Sofa',
        images: [image],
      );
      expect(item.copyWith(isBought: true).images, [image]);
      expect(item.copyWith(images: []).images, isEmpty);
      expect(item.toJson().containsKey('images'), isFalse);
    });

    test('upload names always carry an accepted image extension', () {
      expect(ImageUpload.uploadName('sofa.PNG'), 'sofa.PNG');
      expect(ImageUpload.uploadName('a.webp'), 'a.webp');
      expect(ImageUpload.uploadName('IMG_1.HEIC'), 'IMG_1.jpg');
      expect(ImageUpload.uploadName('blob', mimeType: 'image/png'), 'blob.png');
      expect(ImageUpload.uploadName(''), 'photo.jpg');
      expect(ImageUpload.uploadName('.gif'), '.gif');
    });
  });

  test('recognises pasted image formats by their bytes', () {
    Uint8List bytes(List<int> b) => Uint8List.fromList([...b, 0, 0, 0, 0]);
    expect(imageMimeType(bytes([0x89, 0x50, 0x4E, 0x47])), 'image/png');
    expect(imageMimeType(bytes([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    expect(imageMimeType(bytes([0x47, 0x49, 0x46, 0x38])), 'image/gif');
    expect(
      imageMimeType(
        bytes([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]),
      ),
      'image/webp',
    );
    // TIFF isn't accepted
    expect(imageMimeType(bytes([0x49, 0x49, 0x2A, 0x00])), isNull);
    expect(imageMimeType(Uint8List(0)), isNull);
  });
}
