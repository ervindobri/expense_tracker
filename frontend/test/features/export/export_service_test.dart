import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/export/export_service.dart';

void main() {
  group('exportUri', () {
    test('absolute API base (native)', () {
      final uri = exportUri(
        apiBaseUrl: 'https://tracker.example.ts.net/api/',
        format: ExportFormat.xlsx,
        timezone: 'Europe/Budapest',
      );
      expect(
        uri.toString(),
        'https://tracker.example.ts.net/api/export/'
        '?file_format=xlsx&tz=Europe%2FBudapest',
      );
    });

    test('relative API base resolves against the page (web)', () {
      final uri = exportUri(
        apiBaseUrl: '/api/',
        format: ExportFormat.csv,
        base: Uri.parse('https://tracker.example.ts.net/#/settings'),
      );
      expect(
        uri.toString(),
        'https://tracker.example.ts.net/api/export/?file_format=csv',
      );
    });

    test('leaves out an empty timezone', () {
      final uri = exportUri(
        apiBaseUrl: 'http://127.0.0.1:8000/api/',
        format: ExportFormat.xlsx,
        timezone: '',
      );
      expect(uri.queryParameters, {'file_format': 'xlsx'});
    });
  });
}
