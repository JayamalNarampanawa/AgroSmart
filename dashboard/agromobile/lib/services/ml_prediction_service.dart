import 'dart:convert';
import 'package:http/http.dart' as http;

class MLPredictionResponse {
  final String predictedCrop;
  final double confidence;
  final Map<String, double> probabilities;
  final bool isSuccessful;
  final String? errorMessage;

  MLPredictionResponse({
    required this.predictedCrop,
    required this.confidence,
    required this.probabilities,
    this.isSuccessful = true,
    this.errorMessage,
  });

  factory MLPredictionResponse.fromJson(Map<String, dynamic> json) {
    final probs = <String, double>{};
    final probabilitiesJson = json['probabilities'] as Map<String, dynamic>?;
    if (probabilitiesJson != null) {
      probabilitiesJson.forEach((key, value) {
        probs[key] = (value as num).toDouble();
      });
    }

    return MLPredictionResponse(
      predictedCrop: json['predictedCrop'] ?? 'Unknown',
      confidence: ((json['confidence'] ?? 0) as num).toDouble(),
      probabilities: probs,
      isSuccessful: true,
    );
  }

  factory MLPredictionResponse.error(String message) {
    return MLPredictionResponse(
      predictedCrop: '',
      confidence: 0.0,
      probabilities: {},
      isSuccessful: false,
      errorMessage: message,
    );
  }
}

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();

  factory MLPredictionService() {
    return _instance;
  }

  MLPredictionService._internal();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'ML_CROP_API_BASE_URL',
    defaultValue: '',
  );

  static const List<String> _fallbackBaseUrls = [
    'http://10.0.2.2:8766',
    'http://127.0.0.1:8766',
  ];

  static String _baseUrl = _configuredBaseUrl;

  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  static String getBaseUrl() =>
      _baseUrl.trim().isNotEmpty ? _baseUrl.trim() : _fallbackBaseUrls.first;

  final http.Client _client = http.Client();
  static const Duration timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Predict crop based on input parameters
  /// N: Nitrogen (mg/kg)
  /// P: Phosphorus (mg/kg)
  /// K: Potassium (mg/kg)
  /// temperature: Temperature in Celsius
  /// humidity: Humidity as percentage (0-100)
  /// rainfall: Rainfall in mm
  /// ph: Soil pH value
  Future<MLPredictionResponse> predictCrop({
    required double N,
    required double P,
    required double K,
    required double temperature,
    required double humidity,
    required double rainfall,
    required double ph,
  }) async {
    Object? lastError;

    for (final baseUrl in _baseUrls) {
      try {
        final body = {
          'N': N,
          'P': P,
          'K': K,
          'temperature': temperature,
          'humidity': humidity,
          'rainfall': rainfall,
          'ph': ph,
        };

        final response = await _client
            .post(
              Uri.parse('${_normalize(baseUrl)}/predict'),
              headers: _headers,
              body: json.encode(body),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final jsonResponse =
              json.decode(response.body) as Map<String, dynamic>;
          return MLPredictionResponse.fromJson(jsonResponse);
        }

        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      } catch (e) {
        lastError = e;
      }
    }

    return MLPredictionResponse.error(
      'Connection Error: $lastError. Run the crop ML API and start Flutter with '
      '--dart-define=ML_CROP_API_BASE_URL=http://10.0.2.2:8766',
    );
  }

  List<String> get _baseUrls {
    if (_baseUrl.trim().isNotEmpty) return [_baseUrl.trim()];
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return [_configuredBaseUrl.trim()];
    }
    return _fallbackBaseUrls;
  }

  String _normalize(String baseUrl) {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  /// Test the ML API connection
  Future<bool> testConnection() async {
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client
            .get(
              Uri.parse('${_normalize(baseUrl)}/health'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Get crop details and recommendations
  Future<Map<String, dynamic>> getCropDetails(String cropName) async {
    // This can be extended to fetch crop-specific details from a database
    // For now, returning hardcoded crop information
    return getCropDetailsInfo(cropName);
  }

  static Map<String, dynamic> getCropDetailsInfo(String cropName) {
    final cropInfo = {
      'Rice': {
        'scientificName': 'Oryza sativa',
        'season': 'Monsoon/Kharif',
        'harvestDays': '120-150',
        'temperature': '20-30°C',
        'rainfall': '1500-2250mm',
        'ph': '5.0-7.0',
        'npk': 'N: 80-120, P: 20-40, K: 40-80',
        'description':
            'Rice is the primary staple food for millions worldwide. It thrives in warm, humid climates with adequate water supply.',
        'benefits': [
          'High nutritional value',
          'Good market demand',
          'Relatively short growing period',
          'Supports diverse crop rotations'
        ],
        'challenges': [
          'Water-intensive',
          'Susceptible to pests',
          'Requires proper irrigation',
          'Sensitive to pH variations'
        ],
        'icon': null,
      },
      'Maize': {
        'scientificName': 'Zea mays',
        'season': 'Kharif/Rabi',
        'harvestDays': '90-120',
        'temperature': '21-27°C',
        'rainfall': '500-1000mm',
        'ph': '5.5-7.5',
        'npk': 'N: 80-120, P: 30-60, K: 20-60',
        'description':
            'Corn/Maize is one of the most versatile crops. Used for food, feed, and industrial purposes.',
        'benefits': [
          'Multiple uses',
          'High yield potential',
          'Good market value',
          'Suitable for diverse regions'
        ],
        'challenges': [
          'Vulnerable to water stress',
          'Pest and disease management',
          'Soil fertility depletion',
          'Marketing challenges'
        ],
        'icon': null,
      },
      'Wheat': {
        'scientificName': 'Triticum aestivum',
        'season': 'Rabi',
        'harvestDays': '120-150',
        'temperature': '12-25°C',
        'rainfall': '375-650mm',
        'ph': '6.0-7.5',
        'npk': 'N: 60-100, P: 20-40, K: 20-40',
        'description':
            'Wheat is a major cereal crop, serving as a primary source of carbohydrates and protein.',
        'benefits': [
          'Nutritionally dense',
          'Long shelf life',
          'Good market demand',
          'Winter crop advantage'
        ],
        'challenges': [
          'Weather dependent',
          'Disease susceptibility',
          'Requires proper irrigation',
          'Storage requirements'
        ],
        'icon': null,
      },
      'Tomato': {
        'scientificName': 'Solanum lycopersicum',
        'season': 'Year-round',
        'harvestDays': '60-85',
        'temperature': '18-28°C',
        'rainfall': '500-750mm',
        'ph': '6.0-7.0',
        'npk': 'N: 80-120, P: 60-80, K: 60-100',
        'description':
            'High-value vegetable crop with consistent market demand. Suitable for both field and greenhouse cultivation.',
        'benefits': [
          'High market value',
          'Short farming cycle',
          'Good for value addition',
          'High consumer demand'
        ],
        'challenges': [
          'Disease susceptibility',
          'Water and nutrient intensive',
          'Market price fluctuation',
          'Requires skilled management'
        ],
        'icon': null,
      },
      'Cotton': {
        'scientificName': 'Gossypium hirsutum',
        'season': 'Kharif',
        'harvestDays': '180-210',
        'temperature': '21-27°C',
        'rainfall': '600-1200mm',
        'ph': '6.0-7.5',
        'npk': 'N: 80-120, P: 40-60, K: 20-40',
        'description':
            'Important cash crop for cotton fiber production. Requires careful management for optimal yields.',
        'benefits': [
          'Significant export value',
          'Fiber industry demand',
          'Supports livelihoods',
          'Well-established market'
        ],
        'challenges': [
          'High pesticide requirements',
          'Water intensive',
          'Labor intensive',
          'Market price volatility'
        ],
        'icon': null,
      },
      'Sugarcane': {
        'scientificName': 'Saccharum officinarum',
        'season': 'Kharif',
        'harvestDays': '300-365',
        'temperature': '21-27°C',
        'rainfall': '1200-2250mm',
        'ph': '6.0-7.5',
        'npk': 'N: 80-120, P: 30-60, K: 60-100',
        'description':
            'Major source of sugar and other by-products. Requires substantial investment but offers good returns.',
        'benefits': [
          'Multiple products (sugar, ethanol, bagasse)',
          'Stable prices',
          'Industrial demand',
          'Long growing season advantage'
        ],
        'challenges': [
          'Long crop duration',
          'High water requirement',
          'Nutrient demanding',
          'Pest and disease prone'
        ],
        'icon': null,
      },
      'Soybean': {
        'scientificName': 'Glycine max',
        'season': 'Kharif',
        'harvestDays': '105-120',
        'temperature': '20-30°C',
        'rainfall': '450-900mm',
        'ph': '6.0-7.0',
        'npk': 'N: 20-40, P: 40-60, K: 40-80',
        'description':
            'Protein-rich legume crop. Important for human nutrition and animal feed production.',
        'benefits': [
          'High protein content',
          'Nitrogen fixation ability',
          'Growing international demand',
          'Can improve soil fertility'
        ],
        'challenges': [
          'Market price sensitivity',
          'Pest management',
          'Moisture sensitivity',
          'Processing requirements'
        ],
        'icon': null,
      },
      'Potato': {
        'scientificName': 'Solanum tuberosum',
        'season': 'Rabi',
        'harvestDays': '90-120',
        'temperature': '15-25°C',
        'rainfall': '500-750mm',
        'ph': '5.0-6.5',
        'npk': 'N: 80-120, P: 60-80, K: 80-120',
        'description':
            'Versatile and nutritious staple crop. High yield per acre and good market demand.',
        'benefits': [
          'High nutritional value',
          'Great yield potential',
          'Multiple uses',
          'Growing consumer demand'
        ],
        'challenges': [
          'Disease susceptibility',
          'Pest management',
          'Storage requirements',
          'Labor intensive'
        ],
        'icon': null,
      },
    };

    return cropInfo[cropName] ??
        {
          'scientificName': 'Unknown',
          'season': 'All season',
          'harvestDays': 'N/A',
          'temperature': 'N/A',
          'rainfall': 'N/A',
          'ph': 'N/A',
          'npk': 'N/A',
          'description': 'Crop information not available.',
          'benefits': [],
          'challenges': [],
        };
  }
}
