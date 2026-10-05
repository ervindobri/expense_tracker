import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _operators = {'+', '-', '*', '/'};

/// Inline arithmetic in amount fields is a hardware-keyboard feature:
/// mobile number keyboards have no operator keys.
bool get supportsInlineArithmetic =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

/// Whether [text] is a complete expression with at least one operator,
/// e.g. "123+456" (but not "123" or "123+").
bool isArithmeticExpression(String text) {
  final trimmed = text.replaceAll(' ', '');
  if (trimmed.isEmpty || _operators.contains(trimmed[trimmed.length - 1])) {
    return false;
  }
  return trimmed.substring(1).split('').any(_operators.contains);
}

/// Evaluates a `+ - * /` expression with standard precedence.
/// Returns null for malformed input or a non-finite result (e.g. "5/0").
double? evaluateArithmetic(String text) {
  final tokens = <String>[];
  final normalized = text.replaceAll(' ', '').replaceAll(',', '.');
  final number = StringBuffer();
  for (final char in normalized.split('')) {
    if (_operators.contains(char)) {
      if (number.isEmpty) {
        return null;
      }
      tokens
        ..add(number.toString())
        ..add(char);
      number.clear();
    } else {
      number.write(char);
    }
  }
  if (number.isEmpty) {
    return null;
  }
  tokens.add(number.toString());

  // Collapse * and / first, then sum the remaining terms.
  final terms = <double>[];
  final signs = <int>[1];
  double? current = double.tryParse(tokens.first);
  if (current == null) {
    return null;
  }
  for (var i = 1; i < tokens.length; i += 2) {
    final op = tokens[i];
    final value = double.tryParse(tokens[i + 1]);
    if (value == null) {
      return null;
    }
    switch (op) {
      case '*':
        current = current! * value;
      case '/':
        current = current! / value;
      default:
        terms.add(current!);
        signs.add(op == '-' ? -1 : 1);
        current = value;
    }
  }
  terms.add(current!);

  var result = 0.0;
  for (var i = 0; i < terms.length; i++) {
    result += signs[i] * terms[i];
  }
  return result.isFinite ? result : null;
}

/// Formats an evaluated amount the way the amount fields expect:
/// whole numbers without decimals, otherwise up to 2 decimal places.
String formatArithmeticResult(double value) {
  final rounded = (value * 100).round() / 100;
  if (rounded == rounded.truncateToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

/// Like [DecimalInputFormatter], but also accepts `+ - * /` between operands.
/// Each operand is a decimal number capped at [decimalPlaces], leading zeros
/// are stripped, and typing an operator right after another replaces it.
class ArithmeticInputFormatter extends TextInputFormatter {
  ArithmeticInputFormatter({this.decimalPlaces = 2});
  final int? decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final source = newValue.text
        .replaceAll(',', '.')
        .replaceAll(RegExp('[x×]'), '*')
        .replaceAll('÷', '/')
        .replaceAll(RegExp(r'[^\d.+\-*/]'), '');

    final buffer = StringBuffer();
    var operand = '';

    void flushOperand() {
      var value = operand;
      final dot = value.indexOf('.');
      if (dot != -1) {
        var decimals = value.substring(dot + 1).replaceAll('.', '');
        if (decimalPlaces != null && decimals.length > decimalPlaces!) {
          decimals = decimals.substring(0, decimalPlaces);
        }
        value = '${value.substring(0, dot)}.$decimals';
      }
      if (value.length > 1 && value.startsWith('0') && value[1] != '.') {
        value = value.replaceFirst(RegExp('^0+'), '');
        if (value.isEmpty || value.startsWith('.')) {
          value = '0$value';
        }
      }
      buffer.write(value);
      operand = '';
    }

    for (final char in source.split('')) {
      if (_operators.contains(char)) {
        if (operand.isEmpty) {
          final current = buffer.toString();
          // No leading operator; a repeated operator replaces the previous.
          if (current.isEmpty) {
            continue;
          }
          buffer
            ..clear()
            ..write(current.substring(0, current.length - 1));
        } else {
          flushOperand();
        }
        buffer.write(char);
      } else {
        operand += char;
      }
    }
    flushOperand();

    final text = buffer.toString();
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

/// After the user stops typing for [delay], replaces an arithmetic
/// expression in [controller] (e.g. "123+456") with its result ("579").
/// Negative or invalid results are left as typed so the user can fix them.
void useArithmeticEvaluation(
  TextEditingController controller, {
  bool enabled = true,
  Duration delay = const Duration(milliseconds: 500),
}) {
  useEffect(() {
    if (!enabled) {
      return null;
    }
    Timer? timer;
    void onChanged() {
      timer?.cancel();
      if (!isArithmeticExpression(controller.text)) {
        return;
      }
      timer = Timer(delay, () {
        final result = evaluateArithmetic(controller.text);
        if (result == null || result < 0) {
          return;
        }
        final text = formatArithmeticResult(result);
        controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });
    }

    controller.addListener(onChanged);
    return () {
      timer?.cancel();
      controller.removeListener(onChanged);
    };
  }, [controller, enabled, delay]);
}
