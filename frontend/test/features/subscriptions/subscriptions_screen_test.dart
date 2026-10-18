import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart' show FluentApp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:frontend/features/subscriptions/presentation/subscriptions_screen.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSubscriptionRepository implements ISubscriptionRepository {
  FakeSubscriptionRepository(this.items);

  final List<Subscription> items;

  @override
  Future<List<Subscription>> getSubscriptions() async => items;

  @override
  Future<Subscription> addSubscription(Subscription subscription) async =>
      subscription;

  @override
  Future<Subscription> updateSubscription(Subscription subscription) async =>
      subscription;

  @override
  Future<void> removeSubscription(int id) async {}
}

Future<void> _pumpScreen(WidgetTester tester, List<Subscription> items) async {
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
            FakeSubscriptionRepository(items),
          ),
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
            home: const Scaffold(body: SubscriptionsScreen()),
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
}
