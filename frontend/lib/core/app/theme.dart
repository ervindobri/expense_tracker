import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract final class AppTheme {
  static final AccentColor accent = Colors.blue;

  static final FluentThemeData light = FluentThemeData(
    brightness: Brightness.light,
    accentColor: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: Color(0xffE8E8E8),
    cardColor: Color.fromARGB(255, 255, 255, 255),
    menuColor: Color(0xfff7f7f7)
  );

  static final FluentThemeData dark = FluentThemeData(
    brightness: Brightness.dark,
    accentColor: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: Color(0xff0F0F0F),
    cardColor: Color(0xff000000),
    menuColor: Color(0xff020202)
  );
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // deep link / debugging override: /?theme=light or /?theme=dark
    return switch (Uri.base.queryParameters['theme']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void set(ThemeMode mode) => state = mode;

  void toggle() {
    state = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }
}
