import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/ml_crop_prediction.dart';

class MlCropRecommendationService {
  MlCropRecommendationService._();

  static final MlCropRecommendationService instance =
      MlCropRecommendationService._();

  static const _configuredBaseUrl = String.fromEnvironment(
    'ML_API_BASE_URL',
    defaultValue: '',
  );

  static const _fallbackBaseUrls = [
    'http://10.0.2.2:8000',
    'http://127.0.0.1:8000',
    'https://agrosmart-ml-api.onrender.com',
  ];

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  List<String> get baseUrls {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return [_configuredBaseUrl.trim()];
    }
    return _fallbackBaseUrls;
  }

  Future<MlCropPrediction> predict({
    required double n,
    required double p,
    required double k,
    required double temperature,
    required double humidity,
    required double rainfall,
    required double ph,
  }) async {
    Object? lastError;

    for (final baseUrl in baseUrls) {
      try {
        return await _predictFrom(
          baseUrl: baseUrl,
          n: n,
          p: p,
          k: k,
          temperature: temperature,
          humidity: humidity,
          rainfall: rainfall,
          ph: ph,
        );
      } catch (e) {
        lastError = e;
      }
    }

    throw MlApiException(
      'Unable to reach the ML model API. Last error: $lastError',
    );
  }

  Future<MlCropPrediction> _predictFrom({
    required String baseUrl,
    required double n,
    required double p,
    required double k,
    required double temperature,
    required double humidity,
    required double rainfall,
    required double ph,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/predict');
    final request = await _client.postUrl(uri).timeout(
          const Duration(seconds: 8),
        );

    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(
      jsonEncode({
        'N': n,
        'P': p,
        'K': k,
        'temperature': temperature,
        'humidity': humidity,
        'rainfall': rainfall,
        'ph': ph,
      }),
    );

    final response = await request.close().timeout(const Duration(seconds: 12));
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MlApiException('HTTP ${response.statusCode}: $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const MlApiException('Unexpected ML API response.');
    }

    return MlCropPrediction.fromJson(decoded, sourceUrl: baseUrl);
  }
}

class MlApiException implements Exception {
  final String message;

  const MlApiException(this.message);

  @override
  String toString() => message;
}
