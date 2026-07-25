import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Size get size => MediaQuery.sizeOf(this);
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  double get bottomPadding => MediaQuery.of(this).viewInsets.bottom;
}