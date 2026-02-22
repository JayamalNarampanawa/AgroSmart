class FarmProfile {
  final double n; // Nitrogen
  final double p; // Phosphorus
  final double k; // Potassium
  final double ph; // pH
  final double lat;
  final double lon;
  final String cropType;
  final int soilMoistureWetMin;
  final int soilMoistureDryMax;

  const FarmProfile({
    this.n = 50,
    this.p = 50,
    this.k = 50,
    this.ph = 6.5,
    this.lat = 7.8731,
    this.lon = 80.7718,
    this.cropType = 'kidneybeans',
    this.soilMoistureWetMin = 1200,
    this.soilMoistureDryMax = 4095,
  });

  factory FarmProfile.fromMap(Map<Object?, Object?> data) => FarmProfile(
    n: _d(data['N']) ?? 50,
    p: _d(data['P']) ?? 50,
    k: _d(data['K']) ?? 50,
    ph: _d(data['ph']) ?? 6.5,
    lat: _d(data['lat']) ?? 7.8731,
    lon: _d(data['lon']) ?? 80.7718,
    cropType: data['cropType']?.toString() ?? 'kidneybeans',
    soilMoistureWetMin: (_d(data['soilMoistureWetMin']) ?? 1200).toInt(),
    soilMoistureDryMax: (_d(data['soilMoistureDryMax']) ?? 4095).toInt(),
  );

  Map<String, dynamic> toMap() => {
    'N': n,
    'P': p,
    'K': k,
    'ph': ph,
    'lat': lat,
    'lon': lon,
    'cropType': cropType,
    'soilMoistureWetMin': soilMoistureWetMin,
    'soilMoistureDryMax': soilMoistureDryMax,
  };

  FarmProfile copyWith({
    double? n,
    double? p,
    double? k,
    double? ph,
    double? lat,
    double? lon,
    String? cropType,
    int? soilMoistureWetMin,
    int? soilMoistureDryMax,
  }) => FarmProfile(
    n: n ?? this.n,
    p: p ?? this.p,
    k: k ?? this.k,
    ph: ph ?? this.ph,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    cropType: cropType ?? this.cropType,
    soilMoistureWetMin: soilMoistureWetMin ?? this.soilMoistureWetMin,
    soilMoistureDryMax: soilMoistureDryMax ?? this.soilMoistureDryMax,
  );

  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
