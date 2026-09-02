import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart' show ProgressRing;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('shows a loading indicator until all data is loaded', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeEntryRepository();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: ProviderScope(
          overrides: [
            entryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const App(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProgressRing), findsOneWidget);

    repository.gate.complete();
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProgressRing), findsNothing);
  });
}
