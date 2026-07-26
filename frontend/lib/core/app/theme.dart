import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ignore: avoid_classes_with_only_static_members
abstract final class AppTheme {
  static final AccentColor accent = Colors.blue;

  static final FluentThemeData light = FluentThemeData(
    brightness: Brightness.light,
    accentColor: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color(0xffE8E8E8),
    cardColor: const Color.fromARGB(255, 255, 255, 255),
    menuColor: const Color(0xfff7f7f7),
  );

  static final FluentThemeData dark = FluentThemeData(
    brightness: Brightness.dark,
    accentColor: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color(0xff0F0F0F),
    cardColor: const Color(0xff000000),
    menuColor: const Color(0xff020202),
   
  );
}


extension FluentThemeDataExt on FluentThemeData {
  Color get textColor => brightness == Brightness.dark ? Colors.white : Colors.black;
  Color get inverseTextColor => brightness == Brightness.dark ? Colors.black : Colors.white;
  Color get chipColor => brightness == Brightness.dark ? Colors.white : Colors.black;
  Color get borderColor => brightness == Brightness.dark ? Colors.white : Colors.black;
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
