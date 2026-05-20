import 'package:dio/dio.dart';

/// Builds the shared HTTP client used by market-data adapters. Each adapter
/// passes full URLs (the sources live on different hosts), so no base URL is set.
Dio createDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
