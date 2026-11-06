import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart' show FluentApp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/state/currency_provider.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:frontend/features/shopping/presentation/shopping_list_screen.dart';
import 'package:frontend/features/shopping/presentation/shopping_lists_screen.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_sheet.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_tile.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeShoppingRepository implements IShoppingRepository {
  FakeShoppingRepository(this.lists);

  final List<ShoppingList> lists;
  final addedItems = <ShoppingItem>[];
  final updatedItems = <ShoppingItem>[];
  final removedItems = <int>[];
  final removedLists = <int>[];
  var _nextId = 100;

  /// Makes item updates fail, to check rollbacks.
  bool failUpdates = false;

  @override
  Future<List<ShoppingList>> getLists() async => lists;

  @override
  Future<ShoppingList> addList(String name) async =>
      ShoppingList(id: _nextId++, name: name);

  @override
  Future<ShoppingList> renameList(int id, String name) async =>
      lists.firstWhere((l) => l.id == id).copyWith(name: name);

  @override
  Future<void> removeList(int id) async => removedLists.add(id);

  @override
  Future<ShoppingItem> addItem(ShoppingItem item) async {
    addedItems.add(item);
    return ShoppingItem(
      id: _nextId++,
      listId: item.listId,
      name: item.name,
      description: item.description,
      expectedPrice: item.expectedPrice,
      currency: item.currency,
      buyingGoal: item.buyingGoal,
    );
  }

  @override
  Future<ShoppingItem> updateItem(ShoppingItem item) async {
    if (failUpdates) {
      throw Exception('offline');
    }
    updatedItems.add(item);
    return item;
  }

  @override
  Future<void> removeItem(int id) async => removedItems.add(id);
}

Future<void> _pump(
  WidgetTester tester,
  FakeShoppingRepository repository, {
  Widget home = const ShoppingListsScreen(),
}) async {
  await tester.binding.setSurfaceSize(const Size(500, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: ProviderScope(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          toHufRateProvider.overrideWith((ref, currency) async => 400),
        ],
        child: Builder(
          builder: (context) => FluentApp(
            theme: AppTheme.dark,
            locale: context.locale,
            localizationsDelegates: [
              ...context.localizationDelegates,
              DefaultMaterialLocalizations.delegate,
            ],
            supportedLocales: context.supportedLocales,
            home: home,
          ),
        ),
      ),
    ),
  );
  // Translations load through real async I/O that fake time can't advance,
  // so let real time pass between frames until the screen is built.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

List<ShoppingList> _lists() => [
  ShoppingList(
    id: 1,
    name: 'House',
    items: [
      ShoppingItem(
        id: 10,
        listId: 1,
        name: 'Sofa',
        expectedPrice: 200000,
        buyingGoal: DateTime.now().add(const Duration(days: 5)),
      ),
      const ShoppingItem(id: 11, listId: 1, name: 'Lamp', expectedPrice: 15000),
      const ShoppingItem(
        id: 12,
        listId: 1,
        name: 'Rug',
        expectedPrice: 30000,
        isBought: true,
      ),
    ],
  ),
  const ShoppingList(id: 2, name: 'Groceries'),
];

Finder _section(String title) => find.textContaining(title);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  setUp(rootBundle.clear);

  testWidgets('overview shows each list with what is left to buy', (
    tester,
  ) async {
    await _pump(tester, FakeShoppingRepository(_lists()));

    expect(find.text('Shopping lists'), findsOneWidget);
    expect(find.byType(ShoppingListCard), findsNWidgets(2));
    expect(find.text('House'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.textContaining('2 of 3 left'), findsWidgets);
    expect(find.textContaining('In 5 days'), findsOneWidget);
  });

  testWidgets('shows an empty state without lists', (tester) async {
    await _pump(tester, FakeShoppingRepository([]));
    expect(find.textContaining('No lists yet'), findsOneWidget);
  });

  testWidgets('tapping a list opens its checklist', (tester) async {
    await _pump(tester, FakeShoppingRepository(_lists()));

    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingListScreen), findsOneWidget);
    expect(_section('To buy (2)'), findsOneWidget);
    expect(_section('Bought (1)'), findsOneWidget);
    expect(find.byType(ShoppingItemTile), findsNWidgets(3));
  });

  testWidgets('ticking an item off moves it to bought and saves it', (
    tester,
  ) async {
    final repository = FakeShoppingRepository(_lists());
    await _pump(tester, repository, home: const ShoppingListScreen(listId: 1));

    final lamp = find.ancestor(
      of: find.text('Lamp'),
      matching: find.byType(ShoppingItemTile),
    );
    await tester.tap(
      find.descendant(of: lamp, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();

    expect(_section('To buy (1)'), findsOneWidget);
    expect(_section('Bought (2)'), findsOneWidget);
    expect(repository.updatedItems.single.name, 'Lamp');
    expect(repository.updatedItems.single.isBought, isTrue);
  });

  testWidgets('a failed save puts the item back', (tester) async {
    final repository = FakeShoppingRepository(_lists())..failUpdates = true;
    await _pump(tester, repository, home: const ShoppingListScreen(listId: 1));

    final lamp = find.ancestor(
      of: find.text('Lamp'),
      matching: find.byType(ShoppingItemTile),
    );
    await tester.tap(
      find.descendant(of: lamp, matching: find.byType(IconButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(_section('To buy (2)'), findsOneWidget);
    expect(_section('Bought (1)'), findsOneWidget);
    // let the error toast finish
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('quick add puts a new item on the list', (tester) async {
    final repository = FakeShoppingRepository(_lists());
    await _pump(tester, repository, home: const ShoppingListScreen(listId: 2));
    expect(find.textContaining('Nothing to buy here yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.addedItems.single.name, 'Milk');
    expect(repository.addedItems.single.listId, 2);
    expect(find.text('Milk'), findsOneWidget);
    expect(_section('To buy (1)'), findsOneWidget);
  });

  testWidgets('swiping an item away deletes it', (tester) async {
    final repository = FakeShoppingRepository(_lists());
    await _pump(tester, repository, home: const ShoppingListScreen(listId: 1));

    await tester.drag(find.text('Lamp'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(repository.removedItems, [11]);
    expect(find.text('Lamp'), findsNothing);
  });

  testWidgets('shows the description and saves edits to it', (tester) async {
    final lists = _lists();
    lists[0] = lists[0].copyWith(
      items: [
        lists[0].items.first.copyWith(
          description: 'Grey\nhttps://www.ikea.com/hu/hu/p/sofa-123/',
        ),
        ...lists[0].items.skip(1),
      ],
    );
    final repository = FakeShoppingRepository(lists);
    await _pump(tester, repository, home: const ShoppingListScreen(listId: 1));

    expect(find.text('Grey · ikea.com'), findsOneWidget);
    expect(find.byTooltip('Open link'), findsOneWidget);

    await tester.tap(find.text('Sofa'));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingItemSheet), findsOneWidget);
    expect(find.byType(ShoppingLinkChips), findsOneWidget);

    final description = find.descendant(
      of: find.byType(ShoppingItemSheet),
      matching: find.byWidgetPredicate(
        (w) => w is TextField && w.maxLines == 5,
      ),
    );
    await tester.enterText(description, 'Blue, www.jysk.hu/sofa');
    await tester.pump();
    expect(find.text('jysk.hu'), findsOneWidget);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(
      repository.updatedItems.single.description,
      'Blue, www.jysk.hu/sofa',
    );
    expect(find.text('Blue, jysk.hu'), findsOneWidget);
  });
}
