import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

/// A [ThemeAddon] for switching the active [FluentThemeData] via [FluentTheme].
///
/// The app is built on `fluent_ui`, so widgets read their colors from
/// [FluentTheme] rather than Material's [Theme]. Widgetbook only ships a
/// Material and a Cupertino theme addon, hence this wrapper. A Material
/// [material.Theme] of the same brightness is installed alongside it, because
/// several widgets still reach for `Theme.of(context).textTheme`.
class FluentThemeAddon extends ThemeAddon<FluentThemeData> {
  FluentThemeAddon({required super.themes, super.initialTheme})
    : super(
        themeBuilder: (context, theme, child) {
          return material.Theme(
            data: material.ThemeData(brightness: theme.brightness),
            child: FluentTheme(
              data: theme,
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: DefaultTextStyle(
                  style: theme.typography.body ?? const TextStyle(),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
}
