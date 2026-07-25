
import 'package:flutter/material.dart';

extension TextStyleExt on TextStyle? {
  TextStyle? get bold => this?.copyWith(fontWeight: FontWeight.w700);
  TextStyle? get light => this?.copyWith(fontWeight: FontWeight.w100);
  
}
