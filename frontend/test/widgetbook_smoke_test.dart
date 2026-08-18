import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/widgetbook/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // easy_localization persists the selected locale via shared_preferences.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('widgetbook boots and renders its component tree', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: supportedLocales,
        path: 'assets/translations',
        fallbackLocale: supportedLocales.first,
        child: const ProviderScope(
          child: WidgetbookApp(
            initialRoute: '/?path=core%2Fwidgets%2Fprimarybutton%2Fdefault',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PrimaryButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
