import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart' show ProgressRing;
import 'package:flutter/material.dart' show FloatingActionButton;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/network/internet_connection_provider.dart';
import 'package:frontend/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:frontend/features/shopping/presentation/shopping_lists_screen.dart';
import 'package:frontend/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/shopping/shopping_screen_test.dart'
    show FakeShoppingRepository;
import 'features/subscriptions/subscriptions_screen_test.dart'
    show FakeSubscriptionRepository;

/// Stays online without asking the connectivity plugin, which has no
/// implementation in tests.
class _OnlineNotifier extends InternetConnectionNotifier {
  @override
  InternetConnectionStatus build() => InternetConnectionStatus.online;
}

/// Repository whose reads only complete when the test says so, which makes the
/// initial loading state observable.
class _FakeEntryRepository implements IEntryRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<Category>> getCategories() async {
    await gate.future;
    return [Category(id: 1, name: 'Groceries', type: CategoryType.expense)];
  }

  @override
  Future<EntriesList?> getEntries({int? year}) async {
    await gate.future;
    return EntriesList(
      total: 1,
      items: [
        Entry(
          id: 1,
          amount: 100,
          addedDate: DateTime(2026, 1, 5),
          category: 1,
          createdDate: DateTime(2026, 1, 5),
        ),
      ],
    );
  }

  @override
  Future<int> addEntry(Entry entry) async => 1;

  @override
  Future<bool> removeEntry(int id) async => true;

  @override
  Future<void> updateEntry(Entry copyWith) async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  // The bundle caches the translation load from the previous test's fake
  // async zone, where it never completes for the next test.
  setUp(rootBundle.clear);

  Future<void> pumpApp(WidgetTester tester, _FakeEntryRepository repository) {
    return tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: ProviderScope(
          overrides: [
            entryRepositoryProvider.overrideWithValue(repository),
            subscriptionRepositoryProvider.overrideWithValue(
              FakeSubscriptionRepository([]),
            ),
            shoppingRepositoryProvider.overrideWithValue(
              FakeShoppingRepository([]),
            ),
            internetConnectionProvider.overrideWith(_OnlineNotifier.new),
          ],
          child: const App(),
        ),
      ),
    );
  }

  testWidgets('shows a loading indicator until all data is loaded', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeEntryRepository();

    await pumpApp(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    repository.gate.complete();
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('the floating button opens the shopping lists', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeEntryRepository()..gate.complete();

    await pumpApp(tester, repository);
    // Translations load through real async I/O that fake time can't advance.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ShoppingListsScreen), findsOneWidget);
  });
}
