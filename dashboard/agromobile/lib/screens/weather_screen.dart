import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:card_swiper/card_swiper.dart';

import '../models/weather_now.dart';
import '../services/firebase_service.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  static const double _lat = 7.3;
  static const double _lon = 80.64;
  static const String _owmKey = '7085554067dbfdcfcb40ac08a6ae1a23';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await FirebaseService.instance.refreshWeatherFromOpenWeather(
                  lat: _lat,
                  lon: _lon,
                  apiKey: _owmKey,
                );
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Weather updated from OpenWeather')),
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refresh failed: $e')),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: FirebaseService.instance.weatherStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No weather data'));
          }
          final weather = WeatherNow.fromMap(snapshot.data!);

          return Container(
            decoration: _getWeatherGradient(),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 400),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 20.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        Text(
                          'Live Weather',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weather.description ?? '–',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _mainCard(weather),
                        const SizedBox(height: 16),
                        _detailsGrid(weather),
                        const SizedBox(height: 24),
                        _historySwiper(snapshot.data!),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mainCard(WeatherNow w) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${w.temperature.toStringAsFixed(1)}°C',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Humidity: ${w.humidity.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Wind: ${w.windSpeed.toStringAsFixed(1)} m/s',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Rainfall: ${w.rainfall.toStringAsFixed(1)} mm',
                style: const TextStyle(color: Colors.white70),
              ),
              if (w.updatedAt != null)
                Text(
                  'Updated: ${w.updatedAt}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
          const Icon(Icons.cloud, size: 64, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _detailsGrid(WeatherNow w) {
    final items = [
      _detailTile('Temperature', '${w.temperature.toStringAsFixed(1)}°C'),
      _detailTile('Humidity', '${w.humidity.toStringAsFixed(0)}%'),
      _detailTile('Wind', '${w.windSpeed.toStringAsFixed(1)} m/s'),
      _detailTile('Rain', '${w.rainfall.toStringAsFixed(1)} mm'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: items,
    );
  }

  Widget _detailTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _historySwiper(Map<String, dynamic> weatherNode) {
    final history = weatherNode['history'];
    if (history is! Map) return const SizedBox.shrink();
    final entries = history.values.whereType<Map>().toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: Swiper(
        itemCount: entries.length,
        autoplay: true,
        viewportFraction: 0.8,
        scale: 0.9,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(entries[index]);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Temp: ${(item['temperature'] ?? '--').toString()}°C',
                    style: const TextStyle(color: Colors.white)),
                Text('Humidity: ${(item['humidity'] ?? '--').toString()}%',
                    style: const TextStyle(color: Colors.white70)),
                Text('Wind: ${(item['windSpeed'] ?? '--').toString()} m/s',
                    style: const TextStyle(color: Colors.white70)),
                Text('Rain: ${(item['rainfall'] ?? '--').toString()} mm',
                    style: const TextStyle(color: Colors.white70)),
                Text('Source: ${item['source'] ?? 'N/A'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _getWeatherGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B1221), Color(0xFF0F1B2E), Color(0xFF0B1221)],
      ),
    );
  }
}
