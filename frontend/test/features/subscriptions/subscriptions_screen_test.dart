import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart' show FluentApp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/state/currency_provider.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:frontend/features/subscriptions/presentation/subscriptions_screen.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_form_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSubscriptionRepository implements ISubscriptionRepository {
  FakeSubscriptionRepository(this.items);

  final List<Subscription> items;
  final added = <Subscription>[];

  @override
  Future<List<Subscription>> getSubscriptions() async => items;

  @override
  Future<Subscription> addSubscription(Subscription subscription) async {
    added.add(subscription);
    return subscription;
  }

  final updated = <Subscription>[];

  @override
  Future<Subscription> updateSubscription(Subscription subscription) async {
    updated.add(subscription);
    final i = items.indexWhere((s) => s.id == subscription.id);
    if (i >= 0) {
      items[i] = subscription;
    }
    return subscription;
  }

  @override
  Future<void> removeSubscription(int id) async {}
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<Subscription> items, {
  FakeSubscriptionRepository? repository,
  Widget home = const SubscriptionsScreen(),
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
          subscriptionRepositoryProvider.overrideWithValue(
            repository ?? FakeSubscriptionRepository(items),
          ),
          // fixed rate instead of the network
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
            home: Scaffold(body: home),
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  // The bundle caches the translation load from the previous test's fake
  // async zone, where it never completes for the next test.
  setUp(rootBundle.clear);

  final now = DateTime.now();

  testWidgets('shows renewing soon and toggles active / inactive lists', (
    tester,
  ) async {
    await _pumpScreen(tester, [
      Subscription(
        id: 1,
        name: 'Phone',
        amount: 5000,
        period: SubscriptionPeriod.weekly,
        createdDate: now.subtract(const Duration(days: 2)),
        totalSpent: 5000,
      ),
      Subscription(
        id: 2,
        name: 'Gym',
        amount: 120000,
        period: SubscriptionPeriod.yearly,
        createdDate: now.subtract(const Duration(days: 30)),
      ),
      Subscription(
        id: 3,
        name: 'Old streaming',
        amount: 3000,
        period: SubscriptionPeriod.monthly,
        createdDate: now.subtract(const Duration(days: 90)),
        isActive: false,
        totalSpent: 9000,
      ),
    ]);

    expect(find.text('Renewing soon'), findsOneWidget);
    // weekly phone renews within the window, the yearly gym does not
    expect(
      find.descendant(
        of: find.byType(RenewingSoonCard),
        matching: find.text('Phone'),
      ),
      findsOneWidget,
    );
    expect(find.byType(RenewingSoonCard), findsOneWidget);
    expect(find.byType(SubscriptionCard), findsNWidgets(2));
    expect(find.text('Old streaming'), findsNothing);

    await tester.tap(find.text('Inactive').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SubscriptionCard), findsOneWidget);
    expect(find.text('Old streaming'), findsOneWidget);
  });

  testWidgets('shows empty states without subscriptions', (tester) async {
    await _pumpScreen(tester, []);

    expect(find.text('Nothing renews in the next two weeks.'), findsOneWidget);
    expect(find.textContaining('No active subscriptions yet.'), findsOneWidget);
    expect(find.byType(SubscriptionCard), findsNothing);
  });

  testWidgets('creation date defaults to today and can be picked', (
    tester,
  ) async {
    final repository = FakeSubscriptionRepository([]);
    await _pumpScreen(
      tester,
      [],
      repository: repository,
      home: const Align(
        alignment: Alignment.bottomCenter,
        child: SubscriptionFormSheet(),
      ),
    );

    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Created'));
    await tester.pumpAndSettle();
    // first day of the current month is always selectable (not in the future)
    await tester.tap(find.text('1').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    if (now.day != 1) {
      expect(find.text('Today'), findsNothing);
      expect(
        find.text(DateTime(now.year, now.month).formatDateOnly),
        findsOneWidget,
      );
    }

    await tester.enterText(find.byType(TextField).first, 'Phone');
    await tester.ensureVisible(find.text('Create subscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create subscription'));
    await tester.pump();

    final created = repository.added.single.createdDate;
    expect(
      (created.year, created.month, created.day),
      (now.year, now.month, 1),
    );
    // let the success toast's auto-close timer run out
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('editing from the detail sheet saves and shows the change', (
    tester,
  ) async {
    final repository = FakeSubscriptionRepository([
      Subscription(
        id: 1,
        name: 'Phone',
        amount: 5000,
        period: SubscriptionPeriod.monthly,
        createdDate: now.subtract(const Duration(days: 3)),
      ),
    ]);
    await _pumpScreen(tester, repository.items, repository: repository);

    await tester.tap(find.byType(SubscriptionCard));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Phone'), 'Mobile');
    await tester.pump();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.updated.single.name, 'Mobile');
    // form closed, detail sheet and list show the new name
    expect(find.byType(SubscriptionFormSheet), findsNothing);
    expect(find.text('Mobile'), findsWidgets);
    expect(find.text('Phone'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('foreign prices show the HUF value underneath', (tester) async {
    await _pumpScreen(tester, [
      Subscription(
        id: 1,
        name: 'Spotify',
        amount: 10.5,
        currency: Currency.eur,
        period: SubscriptionPeriod.monthly,
        createdDate: now.subtract(const Duration(days: 40)),
      ),
      Subscription(
        id: 2,
        name: 'Phone',
        amount: 5000,
        period: SubscriptionPeriod.yearly,
        createdDate: now.subtract(const Duration(days: 40)),
      ),
    ]);

    final card = find.ancestor(
      of: find.text('Spotify').last,
      matching: find.byType(SubscriptionCard),
    );
    expect(
      find.descendant(of: card, matching: find.text('10.50 €')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('≈ 4 200 Ft')),
      findsOneWidget,
    );
    // HUF prices get no extra line
    expect(find.textContaining('≈ 5 000'), findsNothing);
  });
}
