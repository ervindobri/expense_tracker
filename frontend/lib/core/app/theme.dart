import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show ShapedInputBorder, InputBorder;
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ignore: avoid_classes_with_only_static_members
abstract final class AppTheme {
  static final AccentColor accent = Colors.blue;

  static final FluentThemeData light = FluentThemeData(
    brightness: Brightness.light,
    accentColor: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color(0xffF7F7F7),
    cardColor: const Color.fromARGB(255, 255, 255, 255),
    menuColor: const Color(0xfff7f7f7),
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      decoration: BoxDecoration(color: Color(0xfff7f7f7)),
    ),
  );

  static final FluentThemeData dark = FluentThemeData(
    brightness: Brightness.dark,
    accentColor: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color(0xff000000),
    cardColor: const Color(0xff0C0C0C),
    menuColor: const Color(0xff020202),
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      decoration: BoxDecoration(color: Color(0xff020202)),
    ),
  );
}

extension FluentThemeDataExt on FluentThemeData {
  Color get textColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black;
  Color get inverseTextColor =>
      brightness == Brightness.dark ? Colors.black : Colors.white;
  Color get chipColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black;
  Color get borderColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black;
  Color get dividerColor => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.1);

  InputBorder inputBorder({bool focused = true}) => ShapedInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadiusGeometry.circular(24.0),
    ),
  );


  List<Color> get gradientBorderColors => brightness == Brightness.dark
      ? [Colors.white, Colors.transparent, Colors.white]
      : [Colors.black, Colors.transparent, Colors.black];

  List<Color> get gradientBorderColors2 => brightness == Brightness.dark
      ? [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.3),
        ]
      : [
          Colors.black.withValues(alpha: 0.3),
          Colors.black.withValues(alpha: 0.3),
        ];


  Color get failureColor => const Color(0xffFd66466);
  Color get successColor => const Color(0xff00b050);


  Color get indicatorColor => brightness == Brightness.dark
      ? const Color(0xff3A3A3A)
      : const Color(0xffE5E5E5);

  Color get containerColor => brightness == Brightness.dark
      ? const Color(0xff1A1A1A)
      : const Color(0xffF5F5F5);
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
      _ => ThemeMode.dark,
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
