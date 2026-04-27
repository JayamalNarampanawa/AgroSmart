class SalesForecastRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String productCategory;
  final String region;
  final String store;
  final bool promoFlag;

  const SalesForecastRequest({
    required this.startDate,
    required this.endDate,
    required this.productCategory,
    required this.region,
    required this.store,
    required this.promoFlag,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'product_category': productCategory,
      'region': region,
      'store': store,
      'promo_flag': promoFlag,
    };
  }

  static String _dateOnly(DateTime value) {
    return value.toIso8601String().split('T').first;
  }
}

class SalesForecastPoint {
  final DateTime date;
  final double predictedSales;
  final double? actualSales;

  const SalesForecastPoint({
    required this.date,
    required this.predictedSales,
    this.actualSales,
  });

  factory SalesForecastPoint.fromJson(Map<String, dynamic> json) {
    return SalesForecastPoint(
      date: DateTime.parse(json['date'].toString()),
      predictedSales: _toDouble(json['predicted_sales']),
      actualSales:
          json['actual_sales'] == null ? null : _toDouble(json['actual_sales']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T').first,
      'predicted_sales': predictedSales,
      if (actualSales != null) 'actual_sales': actualSales,
    };
  }
}

class SalesForecastResponse {
  final double totalPredictedSales;
  final double averageDailySales;
  final double confidenceLow;
  final double confidenceHigh;
  final String modelName;
  final bool isDemo;
  final List<SalesForecastPoint> forecast;
  final Map<String, double> metrics;
  final String? note;

  const SalesForecastResponse({
    required this.totalPredictedSales,
    required this.averageDailySales,
    required this.confidenceLow,
    required this.confidenceHigh,
    required this.modelName,
    required this.isDemo,
    required this.forecast,
    required this.metrics,
    this.note,
  });

  factory SalesForecastResponse.fromJson(Map<String, dynamic> json) {
    final forecastJson = json['forecast'];
    final metricsJson = json['metrics'];
    final metrics = <String, double>{};

    if (metricsJson is Map) {
      metricsJson.forEach((key, value) {
        metrics[key.toString()] = _toDouble(value);
      });
    }

    return SalesForecastResponse(
      totalPredictedSales: _toDouble(json['total_predicted_sales']),
      averageDailySales: _toDouble(json['average_daily_sales']),
      confidenceLow: _toDouble(json['confidence_low']),
      confidenceHigh: _toDouble(json['confidence_high']),
      modelName: json['model_name']?.toString() ?? 'Sales Forecast Model',
      isDemo: json['is_demo'] == true,
      forecast: forecastJson is List
          ? forecastJson
              .whereType<Map>()
              .map((item) => SalesForecastPoint.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      metrics: metrics,
      note: json['note']?.toString(),
    );
  }

  factory SalesForecastResponse.demo(SalesForecastRequest request) {
    final days = request.endDate.difference(request.startDate).inDays + 1;
    final length = days.clamp(1, 60);
    final categoryFactor = _categoryFactor(request.productCategory);
    final regionFactor = _regionFactor(request.region);
    final promoFactor = request.promoFlag ? 1.18 : 1.0;

    final forecast = List.generate(length, (index) {
      final date = request.startDate.add(Duration(days: index));
      final weeklySeasonality = 1 +
          ((date.weekday == 6 || date.weekday == 7)
              ? 0.18
              : (date.weekday == 1 ? -0.08 : 0.0));
      final trend = 1 + index * 0.006;
      final predicted = 850 *
          categoryFactor *
          regionFactor *
          promoFactor *
          weeklySeasonality *
          trend;
      final actual = predicted * (0.92 + ((index % 5) * 0.035));

      return SalesForecastPoint(
        date: date,
        predictedSales: double.parse(predicted.toStringAsFixed(2)),
        actualSales:
            index < 14 ? double.parse(actual.toStringAsFixed(2)) : null,
      );
    });

    final total = forecast.fold<double>(
      0,
      (sum, point) => sum + point.predictedSales,
    );
    final average = total / forecast.length;

    return SalesForecastResponse(
      totalPredictedSales: double.parse(total.toStringAsFixed(2)),
      averageDailySales: double.parse(average.toStringAsFixed(2)),
      confidenceLow: double.parse((total * 0.88).toStringAsFixed(2)),
      confidenceHigh: double.parse((total * 1.12).toStringAsFixed(2)),
      modelName: 'Demo seasonal baseline',
      isDemo: true,
      forecast: forecast,
      metrics: const {
        'rmse': 184.3,
        'mae': 116.7,
        'mape': 8.9,
        'r2': 0.87,
      },
      note:
          'Demo forecast shown because the FastAPI sales model is not connected.',
    );
  }
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

double _categoryFactor(String category) {
  switch (category.toLowerCase()) {
    case 'electronics':
      return 1.42;
    case 'grocery':
      return 1.18;
    case 'fashion':
      return 1.08;
    case 'home':
      return 0.96;
    default:
      return 1.0;
  }
}

double _regionFactor(String region) {
  switch (region.toLowerCase()) {
    case 'west':
      return 1.16;
    case 'south':
      return 1.07;
    case 'east':
      return 0.98;
    case 'north':
      return 0.94;
    default:
      return 1.0;
  }
}
