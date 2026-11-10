import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:url_launcher/url_launcher.dart';

/// File the server builds from every category, entry and subscription.
enum ExportFormat {
  /// One Excel workbook: a sheet per table plus statistics with charts.
  xlsx('Excel (.xlsx)', 'xlsx'),

  /// A zip with one CSV per table, for any spreadsheet app.
  csv('CSV (.zip)', 'csv');

  const ExportFormat(this.display, this.query);

  final String display;

  /// `file_format` value the export endpoint expects.
  final String query;
}

/// The export download URL. [apiBaseUrl] may be relative (`/api/` on web),
/// so it is resolved against [base], the page the app is served from.
Uri exportUri({
  required String apiBaseUrl,
  required ExportFormat format,
  String? timezone,
  Uri? base,
}) {
  final api = (base ?? Uri.base).resolve(apiBaseUrl);
  return api.resolve('export/').replace(
    queryParameters: {
      'file_format': format.query,
      if (timezone != null && timezone.isNotEmpty) 'tz': timezone,
    },
  );
}

/// Starts downloading the export. The server answers with an attachment, so
/// on web the browser saves it without leaving the app, and elsewhere the
/// system browser downloads it (and offers to open it in Excel, Numbers or
/// Sheets). Returns false when nothing could be opened.
Future<bool> downloadExport({
  required String apiBaseUrl,
  required ExportFormat format,
}) async {
  String? timezone;
  try {
    timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    // server's zone then
  }
  final uri = exportUri(
    apiBaseUrl: apiBaseUrl,
    format: format,
    timezone: timezone,
  );
  try {
    return await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      // same tab: an attachment downloads and the app stays open
      webOnlyWindowName: '_self',
    );
  } catch (_) {
    return false;
  }
}
