enum ScadaEventSeverity {
  info,
  success,
  warning,
  critical,
}

class ScadaControlState {
  final bool autoMode;
  final String lastCommand;
  final DateTime? lastCommandAt;
  final String operatorLabel;

  const ScadaControlState({
    required this.autoMode,
    required this.lastCommand,
    required this.lastCommandAt,
    required this.operatorLabel,
  });

  factory ScadaControlState.initial() {
    return const ScadaControlState(
      autoMode: true,
      lastCommand: 'NONE',
      lastCommandAt: null,
      operatorLabel: 'SCADA',
    );
  }

  factory ScadaControlState.fromMap(Map<dynamic, dynamic>? map) {
    final data = map ?? const {};
    final lastCommandAtRaw = data['lastCommandAt'];
    final lastCommandAtMillis = lastCommandAtRaw is num
        ? lastCommandAtRaw.toInt()
        : int.tryParse(lastCommandAtRaw?.toString() ?? '');

    return ScadaControlState(
      autoMode: data['autoMode'] != false,
      lastCommand: data['lastCommand']?.toString() ?? 'NONE',
      lastCommandAt: lastCommandAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastCommandAtMillis),
      operatorLabel: data['operatorLabel']?.toString() ?? 'SCADA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoMode': autoMode,
      'lastCommand': lastCommand,
      'lastCommandAt': lastCommandAt?.millisecondsSinceEpoch,
      'operatorLabel': operatorLabel,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class ScadaEvent {
  final String id;
  final String title;
  final String message;
  final String source;
  final ScadaEventSeverity severity;
  final DateTime timestamp;

  const ScadaEvent({
    required this.id,
    required this.title,
    required this.message,
    required this.source,
    required this.severity,
    required this.timestamp,
  });

  factory ScadaEvent.fromMap(String id, Map<dynamic, dynamic>? map) {
    final data = map ?? const {};
    final timestampRaw = data['timestamp'];
    final timestampMillis = timestampRaw is num
        ? timestampRaw.toInt()
        : int.tryParse(timestampRaw?.toString() ?? '');

    return ScadaEvent(
      id: id,
      title: data['title']?.toString() ?? 'SCADA Event',
      message: data['message']?.toString() ?? '',
      source: data['source']?.toString() ?? 'SCADA',
      severity: ScadaEventSeverity.values.firstWhere(
        (value) => value.name == data['severity'],
        orElse: () => ScadaEventSeverity.info,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        timestampMillis ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'source': source,
      'severity': severity.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
