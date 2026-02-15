import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For APK build, use your computer's IP address or deployed API
  // Replace 'localhost' with your computer's IP address (e.g., '192.168.1.100')
  // or use a deployed API URL (e.g., 'https://your-api.herokuapp.com/api')
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://192.168.1.100:3000/api'; // Replace with your IP
  // static const String baseUrl = 'https://your-deployed-api.com/api'; // Production API
  
  // Mock data mode - set to true to use mock data instead of API
  static const bool useMockData = true;
  static const Duration timeout = Duration(seconds: 10);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Generic GET request
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> _post(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Authentication
  Future<AuthResponse> login(String username, String password) async {
    if (useMockData) {
      // Mock authentication - always successful
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return AuthResponse(
        success: true,
        token: 'mock-jwt-token-${DateTime.now().millisecondsSinceEpoch}',
        user: User(id: 1, username: username, role: 'admin'),
      );
    }
    
    final response = await _post('/auth/login', {
      'username': username,
      'password': password,
    });
    return AuthResponse.fromJson(response);
  }

  // Sensor data
  Future<SensorData> getAllSensorData() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _generateMockSensorData();
    }
    
    final response = await _get('/sensors/all');
    return SensorData.fromJson(response);
  }

  Future<SoilMoistureData> getSoilMoistureData() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final mockData = _generateMockSensorData();
      return mockData.soilMoisture;
    }
    
    final response = await _get('/sensors/soil-moisture');
    return SoilMoistureData.fromJson(response);
  }

  Future<WaterLevelData> getWaterLevelData() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final mockData = _generateMockSensorData();
      return mockData.waterLevel;
    }
    
    final response = await _get('/sensors/water-level');
    return WaterLevelData.fromJson(response);
  }

  Future<LightIntensityData> getLightIntensityData() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final mockData = _generateMockSensorData();
      return mockData.lightIntensity;
    }
    
    final response = await _get('/sensors/light-intensity');
    return LightIntensityData.fromJson(response);
  }

  Future<WeatherData> getWeatherData() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final mockData = _generateMockSensorData();
      return mockData.weather;
    }
    
    final response = await _get('/weather');
    return WeatherData.fromJson(response);
  }

  Future<AnalyticsData> getAnalyticsData() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final mockData = _generateMockSensorData();
      return mockData.analytics;
    }
    
    final response = await _get('/analytics');
    return AnalyticsData.fromJson(response);
  }

  // Control actions
  Future<bool> toggleIrrigation() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true; // Always successful in mock mode
    }
    
    final response = await _post('/irrigation/toggle');
    return response['success'] ?? false;
  }

  Future<bool> toggleSecurity() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true; // Always successful in mock mode
    }
    
    final response = await _post('/security/toggle');
    return response['success'] ?? false;
  }

  Future<bool> toggleCameraRecording() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true; // Always successful in mock mode
    }
    
    final response = await _post('/camera/record');
    return response['success'] ?? false;
  }

  // Health check
  Future<bool> checkHealth() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return true; // Always healthy in mock mode
    }
    
    try {
      await _get('/health');
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }

  // Mock data generation methods
  SensorData _generateMockSensorData() {
    final now = DateTime.now();
    final random = DateTime.now().millisecond / 1000;
    
    return SensorData(
      soilMoisture: SoilMoistureData(
        current: 65.0 + (random * 20 - 10),
        history: _generateMockHistory(24),
        status: 'optimal',
        lastUpdate: now,
      ),
      waterLevel: WaterLevelData(
        current: 78.0 + (random * 15 - 7.5),
        capacity: 1000.0,
        volume: 780.0 + (random * 150 - 75),
        history: _generateMockHistory(24),
        lastUpdate: now,
      ),
      lightIntensity: LightIntensityData(
        current: 750.0 + (random * 400 - 200),
        level: _getLightLevel(750.0 + (random * 400 - 200)),
        history: _generateMockHistory(24),
        lastUpdate: now,
      ),
      irrigation: IrrigationData(
        active: random > 0.7,
        flowRate: random > 0.7 ? 2.5 + random : 0.0,
        duration: random > 0.7 ? (random * 60).toInt() : 0,
        autoMode: true,
        schedule: [
          Schedule(time: '06:00', enabled: true, name: 'Morning'),
          Schedule(time: '14:00', enabled: false, name: 'Afternoon'),
          Schedule(time: '18:00', enabled: true, name: 'Evening'),
        ],
      ),
      security: SecurityData(
        active: true,
        triggered: random > 0.9,
        zones: [
          SecurityZone(name: 'Field Perimeter', active: true, type: 'Motion Sensors'),
          SecurityZone(name: 'Equipment Shed', active: true, type: 'Door Sensor'),
          SecurityZone(name: 'Water Tank Area', active: true, type: 'Camera + Motion'),
          SecurityZone(name: 'Main Gate', active: random > 0.8, type: 'Access Control'),
        ],
        alerts: [],
      ),
      camera: CameraData(
        online: random > 0.1,
        recording: random > 0.8,
        recordings: [
          Recording(name: 'Morning_Inspection_2024.mp4', time: '2 hours ago', size: '45 MB'),
          Recording(name: 'Irrigation_Session_2024.mp4', time: '1 day ago', size: '128 MB'),
          Recording(name: 'Weekly_Growth_2024.mp4', time: '3 days ago', size: '256 MB'),
        ],
      ),
      weather: WeatherData(
        temperature: 24.5 + (random * 10 - 5),
        humidity: 68.0 + (random * 20 - 10),
        windSpeed: 12.3 + (random * 8 - 4),
        pressure: 1013.2 + (random * 20 - 10),
        forecast: _generateMockForecast(),
      ),
      analytics: AnalyticsData(
        dailyWaterUsage: _generateMockUsageData(),
        weeklyGrowth: _generateMockGrowthData(),
        monthlyYield: [],
        efficiency: 87.5 + (random * 10 - 5),
      ),
    );
  }

  List<DataPoint> _generateMockHistory(int hours) {
    final now = DateTime.now();
    final random = DateTime.now().millisecond / 1000;
    
    return List.generate(hours, (index) {
      final timestamp = now.subtract(Duration(hours: hours - index));
      final value = 50 + (random * 40) + (index * 2);
      return DataPoint(timestamp: timestamp, value: value);
    });
  }

  String _getLightLevel(double intensity) {
    if (intensity < 200) return 'low';
    if (intensity < 800) return 'medium';
    return 'high';
  }

  List<WeatherForecast> _generateMockForecast() {
    final now = DateTime.now();
    final conditions = ['sunny', 'cloudy', 'rainy'];
    
    return List.generate(5, (index) {
      final date = now.add(Duration(days: index));
      final random = (DateTime.now().millisecond + index * 100) / 1000;
      
      return WeatherForecast(
        date: date.toIso8601String().split('T')[0],
        temperature: 20.0 + (random * 15),
        humidity: 40.0 + (random * 40),
        condition: conditions[index % conditions.length],
      );
    });
  }

  List<UsageData> _generateMockUsageData() {
    final now = DateTime.now();
    
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final random = (DateTime.now().millisecond + index * 50) / 1000;
      
      return UsageData(
        date: date.toIso8601String().split('T')[0],
        usage: 80.0 + (random * 60),
      );
    });
  }

  List<GrowthData> _generateMockGrowthData() {
    final now = DateTime.now();
    
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final random = (DateTime.now().millisecond + index * 75) / 1000;
      
      return GrowthData(
        date: date.toIso8601String().split('T')[0],
        growth: random * 5,
      );
    });
  }
}

// Data Models
class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? message;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      message: json['message'],
    );
  }
}

class User {
  final int id;
  final String username;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
    );
  }
}

class SensorData {
  final SoilMoistureData soilMoisture;
  final WaterLevelData waterLevel;
  final LightIntensityData lightIntensity;
  final IrrigationData irrigation;
  final SecurityData security;
  final CameraData camera;
  final WeatherData weather;
  final AnalyticsData analytics;

  SensorData({
    required this.soilMoisture,
    required this.waterLevel,
    required this.lightIntensity,
    required this.irrigation,
    required this.security,
    required this.camera,
    required this.weather,
    required this.analytics,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      soilMoisture: SoilMoistureData.fromJson(json['soilMoisture']),
      waterLevel: WaterLevelData.fromJson(json['waterLevel']),
      lightIntensity: LightIntensityData.fromJson(json['lightIntensity']),
      irrigation: IrrigationData.fromJson(json['irrigation']),
      security: SecurityData.fromJson(json['security']),
      camera: CameraData.fromJson(json['camera']),
      weather: WeatherData.fromJson(json['weather']),
      analytics: AnalyticsData.fromJson(json['analytics']),
    );
  }
}

class SoilMoistureData {
  final double current;
  final List<DataPoint> history;
  final String status;
  final DateTime lastUpdate;

  SoilMoistureData({
    required this.current,
    required this.history,
    required this.status,
    required this.lastUpdate,
  });

  factory SoilMoistureData.fromJson(Map<String, dynamic> json) {
    return SoilMoistureData(
      current: (json['current'] ?? 0).toDouble(),
      history: (json['history'] as List?)
          ?.map((e) => DataPoint.fromJson(e))
          .toList() ?? [],
      status: json['status'] ?? '',
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }
}

class WaterLevelData {
  final double current;
  final double capacity;
  final double volume;
  final List<DataPoint> history;
  final DateTime lastUpdate;

  WaterLevelData({
    required this.current,
    required this.capacity,
    required this.volume,
    required this.history,
    required this.lastUpdate,
  });

  factory WaterLevelData.fromJson(Map<String, dynamic> json) {
    return WaterLevelData(
      current: (json['current'] ?? 0).toDouble(),
      capacity: (json['capacity'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      history: (json['history'] as List?)
          ?.map((e) => DataPoint.fromJson(e))
          .toList() ?? [],
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }
}

class LightIntensityData {
  final double current;
  final String level;
  final List<DataPoint> history;
  final DateTime lastUpdate;

  LightIntensityData({
    required this.current,
    required this.level,
    required this.history,
    required this.lastUpdate,
  });

  factory LightIntensityData.fromJson(Map<String, dynamic> json) {
    return LightIntensityData(
      current: (json['current'] ?? 0).toDouble(),
      level: json['level'] ?? '',
      history: (json['history'] as List?)
          ?.map((e) => DataPoint.fromJson(e))
          .toList() ?? [],
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }
}

class IrrigationData {
  final bool active;
  final double flowRate;
  final int duration;
  final bool autoMode;
  final List<Schedule> schedule;

  IrrigationData({
    required this.active,
    required this.flowRate,
    required this.duration,
    required this.autoMode,
    required this.schedule,
  });

  factory IrrigationData.fromJson(Map<String, dynamic> json) {
    return IrrigationData(
      active: json['active'] ?? false,
      flowRate: (json['flowRate'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      autoMode: json['autoMode'] ?? false,
      schedule: (json['schedule'] as List?)
          ?.map((e) => Schedule.fromJson(e))
          .toList() ?? [],
    );
  }
}

class SecurityData {
  final bool active;
  final bool triggered;
  final List<SecurityZone> zones;
  final List<SecurityAlert> alerts;

  SecurityData({
    required this.active,
    required this.triggered,
    required this.zones,
    required this.alerts,
  });

  factory SecurityData.fromJson(Map<String, dynamic> json) {
    return SecurityData(
      active: json['active'] ?? false,
      triggered: json['triggered'] ?? false,
      zones: (json['zones'] as List?)
          ?.map((e) => SecurityZone.fromJson(e))
          .toList() ?? [],
      alerts: (json['alerts'] as List?)
          ?.map((e) => SecurityAlert.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CameraData {
  final bool online;
  final bool recording;
  final List<Recording> recordings;

  CameraData({
    required this.online,
    required this.recording,
    required this.recordings,
  });

  factory CameraData.fromJson(Map<String, dynamic> json) {
    return CameraData(
      online: json['online'] ?? false,
      recording: json['recording'] ?? false,
      recordings: (json['recordings'] as List?)
          ?.map((e) => Recording.fromJson(e))
          .toList() ?? [],
    );
  }
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double pressure;
  final List<WeatherForecast> forecast;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      pressure: (json['pressure'] ?? 0).toDouble(),
      forecast: (json['forecast'] as List?)
          ?.map((e) => WeatherForecast.fromJson(e))
          .toList() ?? [],
    );
  }
}

class AnalyticsData {
  final List<UsageData> dailyWaterUsage;
  final List<GrowthData> weeklyGrowth;
  final List<YieldData> monthlyYield;
  final double efficiency;

  AnalyticsData({
    required this.dailyWaterUsage,
    required this.weeklyGrowth,
    required this.monthlyYield,
    required this.efficiency,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      dailyWaterUsage: (json['dailyWaterUsage'] as List?)
          ?.map((e) => UsageData.fromJson(e))
          .toList() ?? [],
      weeklyGrowth: (json['weeklyGrowth'] as List?)
          ?.map((e) => GrowthData.fromJson(e))
          .toList() ?? [],
      monthlyYield: (json['monthlyYield'] as List?)
          ?.map((e) => YieldData.fromJson(e))
          .toList() ?? [],
      efficiency: (json['efficiency'] ?? 0).toDouble(),
    );
  }
}

// Helper classes
class DataPoint {
  final DateTime timestamp;
  final double value;

  DataPoint({required this.timestamp, required this.value});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class Schedule {
  final String time;
  final bool enabled;
  final String name;

  Schedule({required this.time, required this.enabled, required this.name});

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      time: json['time'] ?? '',
      enabled: json['enabled'] ?? false,
      name: json['name'] ?? '',
    );
  }
}

class SecurityZone {
  final String name;
  final bool active;
  final String type;

  SecurityZone({required this.name, required this.active, required this.type});

  factory SecurityZone.fromJson(Map<String, dynamic> json) {
    return SecurityZone(
      name: json['name'] ?? '',
      active: json['active'] ?? false,
      type: json['type'] ?? '',
    );
  }
}

class SecurityAlert {
  final String type;
  final String location;
  final DateTime timestamp;
  final String severity;
  final bool resolved;

  SecurityAlert({
    required this.type,
    required this.location,
    required this.timestamp,
    required this.severity,
    required this.resolved,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      severity: json['severity'] ?? '',
      resolved: json['resolved'] ?? false,
    );
  }
}

class Recording {
  final String name;
  final String time;
  final String size;

  Recording({required this.name, required this.time, required this.size});

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      name: json['name'] ?? '',
      time: json['time'] ?? '',
      size: json['size'] ?? '',
    );
  }
}

class WeatherForecast {
  final String date;
  final double temperature;
  final double humidity;
  final String condition;

  WeatherForecast({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.condition,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: json['date'] ?? '',
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      condition: json['condition'] ?? '',
    );
  }
}

class UsageData {
  final String date;
  final double usage;

  UsageData({required this.date, required this.usage});

  factory UsageData.fromJson(Map<String, dynamic> json) {
    return UsageData(
      date: json['date'] ?? '',
      usage: (json['usage'] ?? 0).toDouble(),
    );
  }
}

class GrowthData {
  final String date;
  final double growth;

  GrowthData({required this.date, required this.growth});

  factory GrowthData.fromJson(Map<String, dynamic> json) {
    return GrowthData(
      date: json['date'] ?? '',
      growth: (json['growth'] ?? 0).toDouble(),
    );
  }
}

class YieldData {
  final String month;
  final double yield;

  YieldData({required this.month, required this.yield});

  factory YieldData.fromJson(Map<String, dynamic> json) {
    return YieldData(
      month: json['month'] ?? '',
      yield: (json['yield'] ?? 0).toDouble(),
    );
  }
}

// Custom exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}