import 'package:flutter/services.dart';

/// Strips leading zeros as the user types (e.g. "0" + "5" → "5"),
/// while still allowing a bare "0" or a decimal like "0.5" to remain.
class LeadingZeroInputFormatter extends TextInputFormatter {

  const LeadingZeroInputFormatter();
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Allow a lone "0", or "0." while typing a decimal (e.g. "0.5")
    if (text == '0' || text.startsWith('0.')) {
      return newValue;
    }

    // Only reformat if it's a leading zero followed by another digit
    if (text.startsWith('0') && text.length > 1 && text[1] != '.') {
      final stripped = text.replaceFirst(RegExp(r'^0+'), '');
      final newText = stripped.isEmpty ? '0' : stripped;

      final removedCount = text.length - newText.length;
      final newOffset = (newValue.selection.baseOffset - removedCount).clamp(
        0,
        newText.length,
      );

      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }

    return newValue;
  }
}

/// Restricts input to a valid decimal number using ',' as the separator:
/// - only digits and commas allowed
/// - only the first comma is kept; any additional commas are stripped
/// - optionally caps decimal places (default: 2, matching CurrencyFormatter)
class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({this.decimalPlaces = 2});
  final int? decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Strip anything that isn't a digit or comma
    text = text.replaceAll(RegExp(r'[^\d.]'), '');

    // Keep only the first comma; drop any further ones
    final firstComma = text.indexOf('.');
    if (firstComma != -1) {
      final before = text.substring(0, firstComma + 1);
      final after = text.substring(firstComma + 1).replaceAll('.', '');
      text = before + after;

      // Optionally cap decimal digits after the comma
      if (decimalPlaces != null && after.length > decimalPlaces!) {
        text = before + after.substring(0, decimalPlaces!);
      }
    }

    if (text == newValue.text) {
      return newValue;
    }

    final lengthDiff = newValue.text.length - text.length;
    final newOffset = (newValue.selection.baseOffset - lengthDiff).clamp(
      0,
      text.length,
    );

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
