import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';

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
    test('splits items into to buy (soonest goal first) and bought', () {
      final list = ShoppingList.from({
        'id': 1,
        'name': 'House',
        'items': [
          {'id': 1, 'shopping_list': 1, 'name': 'No goal A'},
          {
            'id': 2,
            'shopping_list': 1,
            'name': 'Later',
            'buying_goal': '2027-01-10',
          },
          {'id': 3, 'shopping_list': 1, 'name': 'Done', 'is_bought': true},
          {'id': 4, 'shopping_list': 1, 'name': 'No goal B'},
          {
            'id': 5,
            'shopping_list': 1,
            'name': 'Soon',
            'buying_goal': '2026-12-01',
          },
        ],
      });
      expect(list.toBuy.map((i) => i.name), [
        'Soon',
        'Later',
        'No goal A',
        'No goal B',
      ]);
      expect(list.bought.map((i) => i.name), ['Done']);
    });
  });
}
