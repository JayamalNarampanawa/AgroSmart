import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:card_swiper/card_swiper.dart';
import '../services/api_service.dart';
import 'dart:async';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  WeatherData? weatherData;
  bool isLoading = true;
  Timer? _updateTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadWeatherData();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    try {
      final data = await ApiService().getWeatherData();
      if (!mounted) return;
      setState(() {
        weatherData = data;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading weather data: $e')),
      );
    }
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadWeatherData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: _getWeatherGradient(),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildCurrentWeather(),
                        _buildWeatherDetails(),
                        _buildForecastSection(),
                        _buildWeatherInsights(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  BoxDecoration _getWeatherGradient() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      // Morning
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFF98D8E8)],
        ),
      );
    } else if (hour >= 12 && hour < 18) {
      // Afternoon
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFB0E0E6)],
        ),
      );
    } else {
      // Evening/Night
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Agricultural Zone A',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _loadWeatherData,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AnimationConfiguration.staggeredList(
          position: 0,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weatherData?.temperature.toInt() ?? 0}Â°C',
                                style: GoogleFonts.inter(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _getWeatherDescription(),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _getWeatherIcon(),
                            size: 80,
                            color: _getWeatherColor(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherStat(
                            'Humidity',
                            '${weatherData?.humidity.toInt() ?? 0}%',
                            Icons.water_drop,
                            Colors.blue,
                          ),
                          _buildWeatherStat(
                            'Wind',
                            '${weatherData?.windSpeed.toInt() ?? 0} km/h',
                            Icons.air,
                            Colors.grey,
                          ),
                          _buildWeatherStat(
                            'Pressure',
                            '${weatherData?.pressure.toInt() ?? 0} hPa',
                            Icons.compress,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      'Feels Like',
                      '${(weatherData?.temperature ?? 0) + 2}Â°C',
                      Icons.thermostat,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailCard(
                      'UV Index',
                      '6 High',
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      'Visibility',
                      '10 km',
                      Icons.visibility,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailCard(
                      'Dew Point',
                      '${(weatherData?.temperature ?? 0) - 5}Â°C',
                      Icons.water,
                      Colors.cyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastSection() {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                '5-Day Forecast',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  final forecast = weatherData?.forecast[index];
                  return _buildForecastCard(forecast);
                },
                itemCount: weatherData?.forecast.length ?? 0,
                viewportFraction: 0.8,
                scale: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInsights() {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              Text(
                'Agricultural Insights',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Irrigation Recommendation',
                _getIrrigationRecommendation(),
                Icons.water_drop,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                'Pest Risk',
                _getPestRisk(),
                Icons.bug_report,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                'Growth Conditions',
                _getGrowthConditions(),
                Icons.eco,
                Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(WeatherForecast? forecast) {
    if (forecast == null) return const SizedBox();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDate(forecast.date),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Icon(
              _getForecastIcon(forecast.condition),
              size: 48,
              color: _getForecastColor(forecast.condition),
            ),
            const SizedBox(height: 12),
            Text(
              '${forecast.temperature.toInt()}Â°C',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              forecast.condition.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Humidity: ${forecast.humidity.toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeatherDescription() {
    final temp = weatherData?.temperature ?? 0;
    if (temp > 30) return 'Hot';
    if (temp > 25) return 'Warm';
    if (temp > 20) return 'Pleasant';
    if (temp > 15) return 'Cool';
    return 'Cold';
  }

  IconData _getWeatherIcon() {
    final hour = DateTime.now().hour;
    final temp = weatherData?.temperature ?? 0;
    
    if (hour >= 6 && hour < 18) {
      if (temp > 25) return Icons.wb_sunny;
      return Icons.wb_cloudy;
    } else {
      return Icons.nightlight_round;
    }
  }

  Color _getWeatherColor() {
    final temp = weatherData?.temperature ?? 0;
    if (temp > 30) return Colors.red;
    if (temp > 25) return Colors.orange;
    if (temp > 20) return Colors.yellow;
    return Colors.blue;
  }

  IconData _getForecastIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.wb_cloudy;
      case 'rainy':
        return Icons.grain;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getForecastColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return Colors.orange;
      case 'cloudy':
        return Colors.grey;
      case 'rainy':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getIrrigationRecommendation() {
    final humidity = weatherData?.humidity ?? 0;
    final temp = weatherData?.temperature ?? 0;
    
    if (humidity < 40 && temp > 25) {
      return 'High irrigation needed due to low humidity and high temperature';
    } else if (humidity > 70) {
      return 'Reduce irrigation - high humidity detected';
    } else {
      return 'Normal irrigation schedule recommended';
    }
  }

  String _getPestRisk() {
    final humidity = weatherData?.humidity ?? 0;
    final temp = weatherData?.temperature ?? 0;
    
    if (humidity > 60 && temp > 20 && temp < 30) {
      return 'Medium risk - monitor for fungal diseases';
    } else if (temp > 30) {
      return 'Low risk - hot weather reduces pest activity';
    } else {
      return 'Low risk - conditions not favorable for pests';
    }
  }

  String _getGrowthConditions() {
    final temp = weatherData?.temperature ?? 0;
    final humidity = weatherData?.humidity ?? 0;
    
    if (temp >= 20 && temp <= 28 && humidity >= 50 && humidity <= 70) {
      return 'Excellent - optimal temperature and humidity for growth';
    } else if (temp > 30 || humidity < 40) {
      return 'Challenging - consider shade or additional watering';
    } else {
      return 'Good - suitable conditions for most crops';
    }
  }
}
