import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/internet_connection_provider.dart';

void main() {
  group('resolveConnectionStatus', () {
    test('returns offline when connectivity is none', () {
      final status = resolveConnectionStatus(
        connectivityResults: [ConnectivityResult.none],
        canReachInternet: true,
      );

      expect(status, InternetConnectionStatus.offline);
    });

    test('returns online when connectivity is available and the host is reachable', () {
      final status = resolveConnectionStatus(
        connectivityResults: [ConnectivityResult.wifi],
        canReachInternet: true,
      );

      expect(status, InternetConnectionStatus.online);
    });

    test('returns offline when connectivity is available but the host is unreachable', () {
      final status = resolveConnectionStatus(
        connectivityResults: [ConnectivityResult.mobile],
        canReachInternet: false,
      );

      expect(status, InternetConnectionStatus.offline);
    });
  });
}
