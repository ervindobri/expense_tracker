import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/widgetbook/easy_localization_addon.dart';
import 'package:frontend/widgetbook/fluent_theme_addon.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

const supportedLocales = [Locale('hu', 'HU'), Locale('en', 'US')];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: supportedLocales,
      path: 'assets/translations',
      fallbackLocale: supportedLocales.first,
      child: const ProviderScope(child: WidgetbookApp()),
    ),
  );
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key, this.initialRoute = '/'});

  /// Deep link to open on startup, e.g.
  /// `/?path=core%2Fwidgets%2Fprimarybutton%2Fdefault`.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return Widgetbook(
      initialRoute: initialRoute,
      directories: directories,
      appBuilder: _appBuilder,
      addons: [
        FluentThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Dark', data: AppTheme.dark),
            WidgetbookTheme(name: 'Light', data: AppTheme.light),
          ],
        ),
        EasyLocalizationAddon(locales: supportedLocales),
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          MacosViewports.macbookPro,
        ]),
        AlignmentAddon(),
        TextScaleAddon(),
      ],
    );
  }
}

/// Mirrors the real app shell: `FluentApp` for the fluent widget tree plus a
/// transparent [material.Material] so Material-based widgets (buttons, ink)
/// still find an ancestor. The theme itself comes from [FluentThemeAddon],
/// which is applied inside this builder.
Widget _appBuilder(BuildContext context, Widget child) {
  return FluentApp(
    debugShowCheckedModeBanner: false,
    locale: context.locale,
    localizationsDelegates: context.localizationDelegates,
    supportedLocales: context.supportedLocales,
    home: Builder(
      builder: (context) => material.Material(
        color: material.Colors.transparent,
        child: child,
      ),
    ),
  );
}
