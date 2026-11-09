// ignore_for_file: dead_null_aware_expression
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

/// Override with --dart-define=API_BASE_URL=https://host/api/ when the API
/// is not same-origin (web) or not on localhost (desktop/mobile dev).
const _apiBaseUrl =
    // 'https://expense-tracker.tail0b146d.ts.net/api/' ??
    String.fromEnvironment(
      'API_BASE_URL',
      // on web the app is served from the same host as the API, so a relative
      // URL works everywhere the frontend is deployed
      defaultValue: kIsWeb && !kDebugMode
          ? '/api/'
          : 'http://127.0.0.1:8000/api/',
    );

@riverpod
Dio dioClient(Ref ref) {
  // an explicit --dart-define=API_BASE_URL always wins, so debug builds can
  // target a local backend (http://127.0.0.1:8000/api/) instead of the NAS
  const url = bool.hasEnvironment('API_BASE_URL') || (kIsWeb && !kDebugMode)
      ? _apiBaseUrl
      : 'https://expense-tracker.tail0b146d.ts.net/api/';
  return Dio(BaseOptions(baseUrl: url));
}
