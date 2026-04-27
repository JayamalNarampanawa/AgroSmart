import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sales_forecast.dart';

class SalesForecastApiService {
  SalesForecastApiService._();

  static final SalesForecastApiService instance = SalesForecastApiService._();

  static const _configuredBaseUrl = String.fromEnvironment(
    'SALES_FORECAST_API_BASE_URL',
    defaultValue: '',
  );

  static const _fallbackBaseUrls = [
    'http://10.0.2.2:8765',
    'http://127.0.0.1:8765',
    'http://10.0.2.2:8001',
    'http://127.0.0.1:8001',
  ];

  static const _timeout = Duration(seconds: 10);

  final http.Client _client = http.Client();

  List<String> get baseUrls {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return [_configuredBaseUrl.trim()];
    }
    return _fallbackBaseUrls;
  }

  Future<SalesForecastResponse> predict(SalesForecastRequest request) async {
    Object? lastError;

    for (final baseUrl in baseUrls) {
      try {
        final uri = Uri.parse('${_normalize(baseUrl)}/predict');
        final response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(_timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return SalesForecastResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map),
          );
        }

        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      } catch (e) {
        lastError = e;
      }
    }

    final demo = SalesForecastResponse.demo(request);
    return SalesForecastResponse(
      totalPredictedSales: demo.totalPredictedSales,
      averageDailySales: demo.averageDailySales,
      confidenceLow: demo.confidenceLow,
      confidenceHigh: demo.confidenceHigh,
      modelName: demo.modelName,
      isDemo: true,
      forecast: demo.forecast,
      metrics: demo.metrics,
      note: 'FastAPI unavailable. Using demo forecast. Last error: $lastError',
    );
  }

  Future<bool> healthCheck() async {
    for (final baseUrl in baseUrls) {
      try {
        final response = await _client
            .get(Uri.parse('${_normalize(baseUrl)}/health'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) return true;
      } catch (_) {}
    }
    return false;
  }

  void dispose() {
    _client.close();
  }

  String _normalize(String baseUrl) {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }
}
