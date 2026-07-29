import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Size get size => MediaQuery.sizeOf(this);
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  double get bottomPadding => MediaQuery.of(this).viewInsets.bottom;

  ThemeData get theme => Theme.of(this);
}

extension ThemeExt on BuildContext {
  TextStyle? get headlineSmall => theme.textTheme.headlineMedium;
  TextStyle? get bodyLarge => theme.textTheme.bodyLarge;
  TextStyle? get bodyMedium => theme.textTheme.bodyMedium;
  TextStyle? get bodySmall => theme.textTheme.bodySmall;
}