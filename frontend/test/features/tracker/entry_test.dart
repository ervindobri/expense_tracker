import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';

Map<String, dynamic> _json({Object? currency, Object? originalAmount}) => {
  'id': 1,
  'amount': 4000.0,
  'category': {'id': 3},
  'added_date': '2026-11-06T10:00:00Z',
  'created_date': '2026-11-06T10:00:00Z',
  'currency': ?currency,
  'original_amount': ?originalAmount,
};

void main() {
  group('Entry currency', () {
    test('parses the original currency and value', () {
      final entry = Entry.from(_json(currency: 'EUR', originalAmount: 10.0));
      expect(entry.amount, 4000.0);
      expect(entry.currency, Currency.eur);
      expect(entry.originalAmount, 10.0);
      expect(entry.isForeignCurrency, isTrue);
    });

    test('entries without the fields are HUF, paid at their amount', () {
      final entry = Entry.from(_json());
      expect(entry.currency, Currency.huf);
      expect(entry.originalAmount, 4000.0);
      expect(entry.isForeignCurrency, isFalse);
    });

    test('serializes both amounts and the currency code', () {
      final json = Entry.from(
        _json(currency: 'USD', originalAmount: 12.5),
      ).toJson();
      expect(json['amount'], 4000.0);
      expect(json['currency'], 'USD');
      expect(json['original_amount'], 12.5);
    });

    test('copyWith keeps the currency unless given', () {
      final entry = Entry.from(_json(currency: 'EUR', originalAmount: 10.0));
      final edited = entry.copyWith(amount: 4400, originalAmount: 11);
      expect(edited.currency, Currency.eur);
      expect(edited.originalAmount, 11);
      expect(edited.amount, 4400);
    });
  });
}
