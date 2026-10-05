import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/helpers/arithmetic.dart';

void main() {
  group('evaluateArithmetic', () {
    test('handles the four operations', () {
      expect(evaluateArithmetic('123+456'), 579);
      expect(evaluateArithmetic('500-120'), 380);
      expect(evaluateArithmetic('12*3'), 36);
      expect(evaluateArithmetic('100/8'), 12.5);
    });

    test('respects operator precedence', () {
      expect(evaluateArithmetic('2+3*4'), 14);
      expect(evaluateArithmetic('10-6/2'), 7);
      expect(evaluateArithmetic('1000-200+50*2'), 900);
    });

    test('accepts decimal comma', () {
      expect(evaluateArithmetic('1,5+1,25'), 2.75);
    });

    test('returns null for invalid input', () {
      expect(evaluateArithmetic('5/0'), isNull);
      expect(evaluateArithmetic('5+'), isNull);
      expect(evaluateArithmetic('1..2+3'), isNull);
    });
  });

  test('isArithmeticExpression', () {
    expect(isArithmeticExpression('123+456'), isTrue);
    expect(isArithmeticExpression('123'), isFalse);
    expect(isArithmeticExpression('123+'), isFalse);
    expect(isArithmeticExpression(''), isFalse);
  });

  test('formatArithmeticResult', () {
    expect(formatArithmeticResult(579), '579');
    expect(formatArithmeticResult(12.5), '12.5');
    expect(formatArithmeticResult(10 / 3), '3.33');
  });

  test('parseAmount evaluates pending expressions', () {
    expect('123+456'.parseAmount, 579);
    expect('1 234,5'.parseAmount, 1234.5);
  });

  group('ArithmeticInputFormatter', () {
    final formatter = ArithmeticInputFormatter();
    String format(String text) => formatter
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        )
        .text;

    test('keeps operators and strips other characters', () {
      expect(format('123+456'), '123+456');
      expect(format('12a*3'), '12*3');
      expect(format('12x3÷2'), '12*3/2');
    });

    test('drops leading operator and replaces repeated ones', () {
      expect(format('+12'), '12');
      expect(format('12+-3'), '12-3');
    });

    test('normalizes each operand', () {
      expect(format('007+0.5'), '7+0.5');
      expect(format('1.234+2.5.6'), '1.23+2.56');
    });
  });
}
