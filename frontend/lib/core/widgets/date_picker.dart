import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:frontend/core/app/theme.dart';

/// Material date picker restyled to the app's monochrome look.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime lastDate,
  DateTime? firstDate,
  String? helpText,
}) {
  final first = firstDate ?? DateTime(2000);
  return showDatePicker(
    context: context,
    initialDate: initialDate.isAfter(lastDate)
        ? lastDate
        : initialDate.isBefore(first)
        ? first
        : initialDate,
    firstDate: first,
    lastDate: lastDate,
    helpText: helpText,
    builder: (context, child) {
      final fluent = FluentTheme.of(context);
      final base = Theme.of(context);
      final scheme = fluent.brightness == Brightness.dark
          ? const ColorScheme.dark()
          : const ColorScheme.light();
      return Theme(
        data: base.copyWith(
          colorScheme: scheme.copyWith(
            primary: fluent.chipColor,
            onPrimary: fluent.inverseTextColor,
            surface: fluent.cardColor,
            onSurface: fluent.textColor,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: fluent.cardColor,
            surfaceTintColor: Colors.transparent,
            headerForegroundColor: fluent.textColor,
            dividerColor: fluent.dividerColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: fluent.textColor),
          ),
        ),
        child: child!,
      );
    },
  );
}
