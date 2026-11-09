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
import 'package:frontend/features/shopping/presentation/widgets/shopping_images.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_sheet.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_tile.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_links.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  final reorders = <List<int>>[];

  @override
  Future<ShoppingList> reorderItems(int listId, List<int> itemIds) async {
    reorders.add(itemIds);
    return lists.firstWhere((l) => l.id == listId).reordered(itemIds);
  }

  final uploadedImages = <(int, ImageUpload)>[];
  final removedImages = <int>[];

  /// Makes this many image uploads fail before they work again.
  var failUploads = 0;

  @override
  Future<ShoppingImage> addItemImage(int itemId, ImageUpload image) async {
    if (failUploads > 0) {
      failUploads--;
      throw Exception('upload failed');
    }
    uploadedImages.add((itemId, image));
    final id = _nextId++;
    return ShoppingImage(id: id, url: 'https://example.test/media/$id.jpg');
  }

  @override
  Future<void> removeItemImage(int id) async => removedImages.add(id);
}

/// Hands out [files] for the next pick instead of opening a picker.
class FakeImagePicker extends ImagePickerPlatform {
  List<XFile> files = [];
  final requestedLimits = <int?>[];

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    requestedLimits.add(options.limit);
    return files;
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    requestedLimits.add(1);
    return files.firstOrNull;
  }
}

// on native platforms a picked file's name comes from its path
XFile _photo(String name) =>
    XFile.fromData(Uint8List.fromList([1, 2, 3]), name: name, path: name);

const _sofaImages = [
  ShoppingImage(id: 50, url: 'https://example.test/media/50.jpg'),
  ShoppingImage(id: 51, url: 'https://example.test/media/51.jpg'),
];

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
      const ShoppingItem(
        id: 11,
        listId: 1,
        name: 'Lamp',
        expectedPrice: 15000,
        position: 1,
      ),
      const ShoppingItem(
        id: 12,
        listId: 1,
        name: 'Rug',
        expectedPrice: 30000,
        isBought: true,
        position: 2,
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

  testWidgets('dragging an item by its grip reorders and saves the list', (
    tester,
  ) async {
    final repository = FakeShoppingRepository(_lists());
    await _pump(tester, repository, home: const ShoppingListScreen(listId: 1));

    List<String> toBuyNames() => [
      for (final tile in tester.widgetList<ShoppingItemTile>(
        find.byType(ShoppingItemTile),
      ))
        if (!tile.item.isBought) tile.item.name,
    ];
    // the list's own order, not by goal
    expect(toBuyNames(), ['Sofa', 'Lamp']);

    final lampGrip = find.descendant(
      of: find.ancestor(
        of: find.text('Lamp'),
        matching: find.byType(ShoppingItemTile),
      ),
      matching: find.byType(ReorderableDragStartListener),
    );
    final gesture = await tester.startGesture(tester.getCenter(lampGrip));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(toBuyNames(), ['Lamp', 'Sofa']);
    // the bought rug keeps its place after the to-buy items
    expect(repository.reorders.single, [11, 10, 12]);
  });

  group('photos', () {
    late FakeImagePicker picker;

    setUp(() {
      picker = FakeImagePicker();
      ImagePickerPlatform.instance = picker;
    });

    List<ShoppingList> withSofaPhotos() {
      final lists = _lists();
      lists[0] = lists[0].copyWith(
        items: [
          lists[0].items.first.copyWith(images: _sofaImages),
          ...lists[0].items.skip(1),
        ],
      );
      return lists;
    }

    Finder sheetThumbs() => find.descendant(
      of: find.byType(ShoppingItemSheet),
      matching: find.byType(ShoppingImageThumb),
    );

    Future<void> chooseFromLibrary(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Add photo'));
      await tester.pumpAndSettle();
      // phones (the test platform) offer the camera too
      await tester.tap(find.text('Choose from library'));
      await tester.pumpAndSettle();
    }

    testWidgets('an item with photos shows the first one in its row', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeShoppingRepository(withSofaPhotos()),
        home: const ShoppingListScreen(listId: 1),
      );

      final sofa = find.ancestor(
        of: find.text('Sofa'),
        matching: find.byType(ShoppingItemTile),
      );
      final thumb = find.descendant(
        of: sofa,
        matching: find.byType(ShoppingImageThumb),
      );
      expect(thumb, findsOneWidget);
      expect(
        (tester.widget<ShoppingImageThumb>(thumb).image as NetworkImage).url,
        _sofaImages.first.url,
      );
      // other items have none
      expect(find.byType(ShoppingImageThumb), findsOneWidget);
    });

    testWidgets('removing a photo in the sheet deletes it on save', (
      tester,
    ) async {
      final repository = FakeShoppingRepository(withSofaPhotos());
      await _pump(
        tester,
        repository,
        home: const ShoppingListScreen(listId: 1),
      );

      await tester.tap(find.text('Sofa'));
      await tester.pumpAndSettle();
      expect(sheetThumbs(), findsNWidgets(2));

      await tester.tap(find.byTooltip('Remove photo').first);
      await tester.pump();
      expect(sheetThumbs(), findsOneWidget);
      // nothing is deleted until the item is saved
      expect(repository.removedImages, isEmpty);

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repository.removedImages, [50]);
      expect(find.byType(ShoppingItemSheet), findsNothing);
      final row = tester.widget<ShoppingImageThumb>(
        find.byType(ShoppingImageThumb),
      );
      expect((row.image as NetworkImage).url, _sofaImages.last.url);
    });

    testWidgets('closing the sheet without saving keeps the photos', (
      tester,
    ) async {
      final repository = FakeShoppingRepository(withSofaPhotos());
      await _pump(
        tester,
        repository,
        home: const ShoppingListScreen(listId: 1),
      );

      await tester.tap(find.text('Sofa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove photo').first);
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemSheet), findsNothing);
      expect(repository.removedImages, isEmpty);
    });

    testWidgets('picked photos upload once the new item is saved', (
      tester,
    ) async {
      final repository = FakeShoppingRepository(_lists());
      await _pump(
        tester,
        repository,
        home: const ShoppingListScreen(listId: 2),
      );

      await tester.tap(find.byTooltip('Add item').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(ShoppingItemSheet),
              matching: find.byType(TextField),
            )
            .first,
        'Milk',
      );
      picker.files = [_photo('milk.png'), _photo('IMG_0001.HEIC')];
      await chooseFromLibrary(tester);

      expect(picker.requestedLimits, [10]);
      expect(sheetThumbs(), findsNWidgets(2));
      expect(repository.uploadedImages, isEmpty);

      await tester.tap(find.text('Add item').last);
      await tester.pumpAndSettle();

      expect(repository.addedItems.single.name, 'Milk');
      // the fake hands out ids from 100
      expect(repository.uploadedImages.map((u) => u.$1), [100, 100]);
      expect(repository.uploadedImages.map((u) => u.$2.filename), [
        'milk.png',
        'IMG_0001.jpg',
      ]);
      expect(find.byType(ShoppingItemSheet), findsNothing);
      expect(find.byType(ShoppingImageThumb), findsOneWidget);
    });

    testWidgets('saving again after a failed upload does not add the item '
        'twice', (tester) async {
      final repository = FakeShoppingRepository(_lists())..failUploads = 1;
      await _pump(
        tester,
        repository,
        home: const ShoppingListScreen(listId: 2),
      );

      await tester.tap(find.byTooltip('Add item').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(ShoppingItemSheet),
              matching: find.byType(TextField),
            )
            .first,
        'Milk',
      );
      picker.files = [_photo('a.jpg'), _photo('b.jpg')];
      await chooseFromLibrary(tester);

      await tester.tap(find.text('Add item').last);
      await tester.pumpAndSettle();
      // the item was added, its photos weren't: the sheet stays open
      expect(repository.addedItems, hasLength(1));
      expect(repository.uploadedImages, isEmpty);
      expect(find.byType(ShoppingItemSheet), findsOneWidget);

      await tester.tap(find.text('Add item').last);
      await tester.pumpAndSettle();

      expect(repository.addedItems, hasLength(1));
      expect(repository.updatedItems.single.name, 'Milk');
      expect(repository.uploadedImages.map((u) => u.$2.filename), [
        'a.jpg',
        'b.jpg',
      ]);
      expect(find.byType(ShoppingItemSheet), findsNothing);
      // let the error toast finish
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('only offers to pick what still fits', (tester) async {
      final lists = _lists();
      lists[0] = lists[0].copyWith(
        items: [
          lists[0].items.first.copyWith(
            images: [
              for (var i = 0; i < maxItemImages - 3; i++)
                ShoppingImage(id: 60 + i, url: 'https://example.test/$i.jpg'),
            ],
          ),
          ...lists[0].items.skip(1),
        ],
      );
      await _pump(
        tester,
        FakeShoppingRepository(lists),
        home: const ShoppingListScreen(listId: 1),
      );
      await tester.tap(find.text('Sofa'));
      await tester.pumpAndSettle();

      picker.files = [for (var i = 0; i < 5; i++) _photo('$i.jpg')];
      await chooseFromLibrary(tester);

      expect(picker.requestedLimits, [3]);
      expect(sheetThumbs(), findsNWidgets(maxItemImages));
      // full now
      expect(find.byTooltip('At most 10 photos per item'), findsOneWidget);
    });

    /// Answers the clipboard plugin with [image] (null: no image) and the
    /// system clipboard with [text].
    void mockClipboard(WidgetTester tester, {Uint8List? image, String? text}) {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('pasteboard'),
        (call) async => call.method == 'image' ? image : null,
      );
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        return switch (call.method) {
          'Clipboard.getData' => text == null ? null : {'text': text},
          'Clipboard.hasStrings' => {'value': text != null},
          _ => null,
        };
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('pasteboard'),
          null,
        );
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
    }

    Future<void> pressPaste(WidgetTester tester) async {
      // the test platform is Android, which pastes with Ctrl+V
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    Finder descriptionField() => find.descendant(
      of: find.byType(ShoppingItemSheet),
      matching: find.byWidgetPredicate(
        (w) => w is TextField && w.maxLines == 5,
      ),
    );

    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]);

    testWidgets('pasting an image adds it and uploads it on save', (
      tester,
    ) async {
      final repository = FakeShoppingRepository(withSofaPhotos());
      await _pump(
        tester,
        repository,
        home: const ShoppingListScreen(listId: 1),
      );
      mockClipboard(tester, image: png, text: 'ignored');

      await tester.tap(find.text('Sofa'));
      await tester.pumpAndSettle();
      await tester.tap(descriptionField());
      await tester.pump();
      await pressPaste(tester);

      expect(sheetThumbs(), findsNWidgets(3));
      // the image won, so no text was pasted
      expect(
        tester.widget<TextField>(descriptionField()).controller!.text,
        isEmpty,
      );

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(repository.uploadedImages.single.$1, 10);
      expect(repository.uploadedImages.single.$2.filename, 'pasted.png');
      expect(repository.uploadedImages.single.$2.bytes, png);
    });

    testWidgets('pasting without an image on the clipboard pastes text', (
      tester,
    ) async {
      final repository = FakeShoppingRepository(withSofaPhotos());
      await _pump(
        tester,
        repository,
        home: const ShoppingListScreen(listId: 1),
      );
      mockClipboard(tester, text: 'Grey velvet');

      await tester.tap(find.text('Sofa'));
      await tester.pumpAndSettle();
      await tester.tap(descriptionField());
      await tester.pump();
      await pressPaste(tester);

      expect(sheetThumbs(), findsNWidgets(2));
      expect(
        tester.widget<TextField>(descriptionField()).controller!.text,
        'Grey velvet',
      );
    });

    testWidgets('the menu pastes an image, or says there is none', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeShoppingRepository(_lists()),
        home: const ShoppingListScreen(listId: 1),
      );
      mockClipboard(tester);

      await tester.tap(find.text('Lamp'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paste image'));
      await tester.pumpAndSettle();

      expect(find.text('No image on the clipboard'), findsOneWidget);
      expect(sheetThumbs(), findsNothing);

      mockClipboard(tester, image: png);
      await tester.tap(find.byTooltip('Add photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paste image'));
      await tester.pumpAndSettle();
      expect(sheetThumbs(), findsOneWidget);
      // let the toast finish
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('tapping a photo opens it full screen', (tester) async {
      await _pump(
        tester,
        FakeShoppingRepository(withSofaPhotos()),
        home: const ShoppingListScreen(listId: 1),
      );

      await tester.tap(find.byType(ShoppingImageThumb));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byType(ShoppingItemSheet), findsNothing);
      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
    });
  });
}
