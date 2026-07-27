import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InternetConnectionStatus { unknown, online, offline }

final internetConnectionProvider =
    NotifierProvider<InternetConnectionNotifier, InternetConnectionStatus>(
  InternetConnectionNotifier.new,
);

class InternetConnectionNotifier extends Notifier<InternetConnectionStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasInitialized = false;

  @override
  InternetConnectionStatus build() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initialize();
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return InternetConnectionStatus.unknown;
  }

  Future<void> _initialize() async {
    final initialConnectivity = await _connectivity.checkConnectivity();
    state = await _resolveStatus(initialConnectivity);

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      state = await _resolveStatus(results);
    });
  }

  Future<InternetConnectionStatus> _resolveStatus(
    List<ConnectivityResult> connectivityResults,
  ) async {
    if (connectivityResults.contains(ConnectivityResult.none)) {
      return InternetConnectionStatus.offline;
    }

    try {
      final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
      );

      return resolveConnectionStatus(
        connectivityResults: connectivityResults,
        canReachInternet: result.isNotEmpty,
      );
    } on SocketException {
      return InternetConnectionStatus.offline;
    } on TimeoutException {
      return InternetConnectionStatus.offline;
    } on HandshakeException {
      return InternetConnectionStatus.offline;
    } catch (_) {
      return InternetConnectionStatus.offline;
    }
  }
}

InternetConnectionStatus resolveConnectionStatus({
  required List<ConnectivityResult> connectivityResults,
  required bool canReachInternet,
}) {
  if (connectivityResults.contains(ConnectivityResult.none)) {
    return InternetConnectionStatus.offline;
  }

  return canReachInternet
      ? InternetConnectionStatus.online
      : InternetConnectionStatus.offline;
}
