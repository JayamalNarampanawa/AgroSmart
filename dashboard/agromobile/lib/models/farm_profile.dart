class FarmProfile {
  final double n;
  final double p;
  final double k;
  final double ph;
  final bool phIsDefault;

  FarmProfile({
    required this.n,
    required this.p,
    required this.k,
    required this.ph,
    required this.phIsDefault,
  });

  factory FarmProfile.fromMap(Map<dynamic, dynamic>? data) {
    final map = data ?? {};
    double readNum(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    final ph = readNum(map['ph'], 6.5);
    return FarmProfile(
      n: readNum(map['N'], 0),
      p: readNum(map['P'], 0),
      k: readNum(map['K'], 0),
      ph: ph,
      phIsDefault: map['phIsDefault'] == true || ph == 6.5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'N': n,
      'P': p,
      'K': k,
      'ph': ph,
      'phIsDefault': phIsDefault,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

