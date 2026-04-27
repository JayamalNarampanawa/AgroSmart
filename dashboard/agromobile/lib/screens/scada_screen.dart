import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/crop_recommendation.dart';
import '../models/farm_profile.dart';
import '../models/notification_model.dart';
import '../models/scada_state.dart';
import '../models/sensor_data.dart';
import '../services/crop_recommendation_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/sensor_history_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_scaffold.dart';

class ScadaScreen extends StatefulWidget {
  const ScadaScreen({super.key});

  @override
  State<ScadaScreen> createState() => _ScadaScreenState();
}

enum _ScadaViewMode {
  dashboard,
  digitalTwin,
}

class _ScadaScreenState extends State<ScadaScreen> {
  _ScadaViewMode _viewMode = _ScadaViewMode.dashboard;
  bool _isRunningCommand = false;

  Future<void> _runCommand({
    required Future<void> Function() action,
    required String message,
    required Color color,
  }) async {
    if (_isRunningCommand) return;

    setState(() => _isRunningCommand = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command failed: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accentRose,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunningCommand = false);
      }
    }
  }

  Future<void> _setControlMode(bool autoMode) {
    return _runCommand(
      action: () async {
        await FirebaseService.instance.setControlMode(autoMode);
        NotificationService.instance.addNotification(
          title: autoMode ? 'SCADA Auto Mode Enabled' : 'SCADA Manual Mode Enabled',
          message: autoMode
              ? 'Pump commands now follow the automatic control logic.'
              : 'Direct operator commands are now enabled from the SCADA console.',
          type: NotificationType.info,
          priority: NotificationPriority.normal,
          source: 'SCADA',
          duplicateWindow: const Duration(seconds: 20),
        );
      },
      message: autoMode ? 'Switched to AUTO mode' : 'Switched to MANUAL mode',
      color: autoMode ? AppColors.accentCyan : AppColors.accentOrange,
    );
  }

  Future<void> _setPumpState(bool on, ScadaControlState control) {
    if (control.autoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switch to MANUAL mode before sending direct pump commands.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return Future.value();
    }

    return _runCommand(
      action: () async {
        await FirebaseService.instance.setPumpState(on);
        NotificationService.instance.addNotification(
          title: on ? 'SCADA Pump Started' : 'SCADA Pump Stopped',
          message: on
              ? 'The irrigation pump was started from the supervisory console.'
              : 'The irrigation pump was stopped from the supervisory console.',
          type: on ? NotificationType.success : NotificationType.warning,
          priority: NotificationPriority.high,
          source: 'SCADA',
          duplicateWindow: const Duration(seconds: 20),
        );
      },
      message: on ? 'Pump command sent: ON' : 'Pump command sent: OFF',
      color: on ? AppColors.accentGreen : AppColors.accentRose,
    );
  }

  Future<void> _resetAlarms(int activeAlarms) {
    return _runCommand(
      action: () async {
        await FirebaseService.instance.resetScadaAlarms(
          acknowledged: activeAlarms,
        );
        NotificationService.instance.markAllAsRead();
        NotificationService.instance.addNotification(
          title: 'SCADA Alarm Reset',
          message: activeAlarms > 0
              ? '$activeAlarms active alarm(s) were acknowledged by the operator.'
              : 'Alarm acknowledgements were reset from the SCADA console.',
          type: NotificationType.info,
          priority: NotificationPriority.normal,
          source: 'SCADA',
          duplicateWindow: const Duration(seconds: 20),
        );
      },
      message: activeAlarms > 0
          ? 'Alarm acknowledgement sent'
          : 'Alarm reset command sent',
      color: AppColors.accentOrange,
    );
  }

  Future<CropRecommendation?> _loadRecommendation(FarmProfile profile) async {
    if (profile.n <= 0 && profile.p <= 0 && profile.k <= 0) {
      return null;
    }

    final recommendations = await CropRecommendationService.instance
        .getRecommendations(profile, topN: 1);
    if (recommendations.isEmpty) return null;
    return recommendations.first;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<SensorData?>(
        stream: FirebaseService.instance.currentDataStream(),
        initialData: FirebaseService.instance.latestSensorData,
        builder: (context, liveSnapshot) {
          final liveData = liveSnapshot.data;

          return StreamBuilder<List<SensorData>>(
            stream: FirebaseService.instance.historyStream(limit: 120),
            builder: (context, remoteHistorySnapshot) {
              final remoteHistory =
                  remoteHistorySnapshot.data ?? const <SensorData>[];
              if (remoteHistory.isNotEmpty) {
                SensorHistoryCacheService.instance.cacheSnapshots(remoteHistory);
              }

              return ValueListenableBuilder<List<SensorData>>(
                valueListenable: SensorHistoryCacheService.instance.history,
                builder: (context, localHistory, _) {
                  final history = SensorHistoryCacheService.instance
                      .mergeWithRemote(remoteHistory);

                  return StreamBuilder<bool>(
                    stream: FirebaseService.instance.realtimeConnectionStream(),
                    initialData: liveData != null,
                    builder: (context, connectionSnapshot) {
                      final connected = connectionSnapshot.data == true;
                      final alarms = _deriveAlarms(
                        data: liveData,
                        connected: connected,
                      );
                      final criticalAlarms = alarms
                          .where((alarm) => alarm.severity == _AlarmSeverity.critical)
                          .length;

                      return StreamBuilder<FarmProfile>(
                        stream: FirebaseService.instance.farmProfileStream(),
                        initialData: FarmProfile.fromMap(null),
                        builder: (context, profileSnapshot) {
                          final profile =
                              profileSnapshot.data ?? FarmProfile.fromMap(null);

                          return StreamBuilder<ScadaControlState>(
                            stream: FirebaseService.instance.scadaControlStream(),
                            initialData: ScadaControlState.initial(),
                            builder: (context, controlSnapshot) {
                              final control =
                                  controlSnapshot.data ?? ScadaControlState.initial();

                              return StreamBuilder<List<ScadaEvent>>(
                                stream: FirebaseService.instance
                                    .scadaEventStream(limit: 10),
                                initialData: const <ScadaEvent>[],
                                builder: (context, eventSnapshot) {
                                  final scadaEvents =
                                      eventSnapshot.data ?? const <ScadaEvent>[];

                                  return ValueListenableBuilder<List<NotificationModel>>(
                                    valueListenable:
                                        NotificationService.instance.notifications,
                                    builder: (context, notifications, _) {
                                      final timeline = _buildTimeline(
                                        scadaEvents: scadaEvents,
                                        notifications: notifications,
                                      );

                                      return RefreshIndicator(
                                        color: AppColors.accentCyan,
                                        onRefresh: () async {
                                          setState(() {});
                                        },
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final viewportWidth =
                                                constraints.maxWidth;
                                            final wide = viewportWidth >= 1200;
                                            final medium =
                                                viewportWidth >= 760;
                                            final compact =
                                                viewportWidth < 560;
                                            final contentPadding =
                                                medium ? AppSpacing.xl : AppSpacing.lg;

                                            final summaryColumns =
                                                viewportWidth >= 1360
                                                    ? 4
                                                    : viewportWidth >= 980
                                                        ? 3
                                                        : viewportWidth >= 560
                                                            ? 2
                                                            : 1;
                                            final summaryWidth = _tileWidth(
                                              viewportWidth -
                                                  ((compact
                                                              ? AppSpacing.md
                                                              : medium
                                                                  ? AppSpacing.xl
                                                                  : AppSpacing.lg) *
                                                          2),
                                              summaryColumns,
                                            );

                                            final systemColumns =
                                                viewportWidth >= 1280
                                                    ? 4
                                                    : viewportWidth >= 760
                                                        ? 2
                                                        : 1;
                                            final systemWidth = _tileWidth(
                                              viewportWidth -
                                                  ((compact
                                                              ? AppSpacing.md
                                                              : medium
                                                                  ? AppSpacing.xl
                                                                  : AppSpacing.lg) *
                                                          2),
                                              systemColumns,
                                            );

                                            final leftRail = Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _ScadaPanel(
                                                  title: _viewMode ==
                                                          _ScadaViewMode.dashboard
                                                      ? 'Process Overview'
                                                      : 'Digital Twin',
                                                  accent: AppColors.accentCyan,
                                                  child: _viewMode ==
                                                          _ScadaViewMode.dashboard
                                                      ? _ProcessOverview(
                                                          control: control,
                                                          connected: connected,
                                                          data: liveData,
                                                          alarms: alarms,
                                                        )
                                                      : _DigitalTwinBoard(
                                                          data: liveData,
                                                          control: control,
                                                          connected: connected,
                                                          alarms: alarms,
                                                        ),
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.section,
                                                ),
                                                _ScadaPanel(
                                                  title: 'Live Sensor Panels',
                                                  accent: AppColors.accentCyan,
                                                  child: _SensorPanelGrid(
                                                    data: liveData,
                                                    connected: connected,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.section,
                                                ),
                                                _ScadaPanel(
                                                  title: 'Trend Monitoring',
                                                  accent: AppColors.accentCyan,
                                                  child: _TrendGrid(history: history),
                                                ),
                                              ],
                                            );

                                            final rightRail = Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _AlarmPanel(alarms: alarms),
                                                const SizedBox(
                                                  height: AppSpacing.section,
                                                ),
                                                FutureBuilder<CropRecommendation?>(
                                                  future:
                                                      _loadRecommendation(profile),
                                                  builder: (context, snapshot) {
                                                    return _RecommendationPanel(
                                                      profile: profile,
                                                      recommendation:
                                                          snapshot.data,
                                                      loading:
                                                          snapshot.connectionState ==
                                                              ConnectionState.waiting,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.section,
                                                ),
                                                _EventLogPanel(timeline: timeline),
                                                const SizedBox(
                                                  height: AppSpacing.section,
                                                ),
                                                _SupervisoryControlsPanel(
                                                  control: control,
                                                  data: liveData,
                                                  busy: _isRunningCommand,
                                                  activeAlarms: alarms.length,
                                                  onAutoMode: () =>
                                                      _setControlMode(true),
                                                  onManualMode: () =>
                                                      _setControlMode(false),
                                                  onPumpOn: () =>
                                                      _setPumpState(true, control),
                                                  onPumpOff: () =>
                                                      _setPumpState(false, control),
                                                  onResetAlarms: () =>
                                                      _resetAlarms(alarms.length),
                                                ),
                                              ],
                                            );

                                            return SingleChildScrollView(
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              padding: EdgeInsets.fromLTRB(
                                                contentPadding,
                                                AppSpacing.md,
                                                contentPadding,
                                                AppSpacing.sectionLarge,
                                              ),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Color(0xFF0D1324),
                                                      Color(0xFF050915),
                                                      Color(0xFF02050C),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF12314E),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.28),
                                                      blurRadius: 24,
                                                      offset:
                                                          const Offset(0, 18),
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                    compact
                                                        ? AppSpacing.md
                                                        : medium
                                                            ? AppSpacing.xl
                                                            : AppSpacing.lg,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      _ScadaHeader(
                                                        viewMode: _viewMode,
                                                        onSelectView: (mode) {
                                                          setState(() {
                                                            _viewMode = mode;
                                                          });
                                                        },
                                                      ),
                                                      const SizedBox(
                                                        height:
                                                            AppSpacing.section,
                                                      ),
                                                      Wrap(
                                                        spacing: AppSpacing.md,
                                                        runSpacing:
                                                            AppSpacing.md,
                                                        children: [
                                                          SizedBox(
                                                            width: summaryWidth,
                                                            child: _SummaryCard(
                                                              title: 'Total Alarms',
                                                              value:
                                                                  alarms.length.toString(),
                                                              tone:
                                                                  const Color(0xFF0C3D47),
                                                              border:
                                                                  const Color(0xFF0E7C86),
                                                              statusDot:
                                                                  alarms.isEmpty
                                                                      ? AppColors
                                                                          .accentGreen
                                                                      : AppColors
                                                                          .accentOrange,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: summaryWidth,
                                                            child: _SummaryCard(
                                                              title: 'Critical',
                                                              value: criticalAlarms
                                                                  .toString(),
                                                              tone:
                                                                  const Color(0xFF33161E),
                                                              border:
                                                                  const Color(0xFF9B2C46),
                                                              statusDot:
                                                                  criticalAlarms > 0
                                                                      ? AppColors
                                                                          .accentRose
                                                                      : AppColors
                                                                          .accentGreen,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: summaryWidth,
                                                            child: _SummaryCard(
                                                              title: 'Control Mode',
                                                              value: control.autoMode
                                                                  ? 'AUTO'
                                                                  : 'MANUAL',
                                                              tone:
                                                                  const Color(0xFF0A2340),
                                                              border:
                                                                  const Color(0xFF1C7ED6),
                                                              statusDot: control
                                                                      .autoMode
                                                                  ? AppColors
                                                                      .accentCyan
                                                                  : AppColors
                                                                      .accentOrange,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: summaryWidth,
                                                            child: _SummaryCard(
                                                              title: 'Pump Status',
                                                              value: liveData
                                                                          ?.pumpStatus ==
                                                                      true
                                                                  ? 'ON'
                                                                  : 'OFF',
                                                              tone:
                                                                  const Color(0xFF171D33),
                                                              border:
                                                                  const Color(0xFF3C4A6E),
                                                              statusDot: liveData
                                                                          ?.pumpStatus ==
                                                                      true
                                                                  ? AppColors
                                                                      .accentGreen
                                                                  : const Color(
                                                                      0xFF8392B6),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: summaryWidth,
                                                            child: _SummaryCard(
                                                              title: 'Connection',
                                                              value: connected
                                                                  ? 'ONLINE'
                                                                  : 'OFFLINE',
                                                              tone:
                                                                  const Color(0xFF0C3D35),
                                                              border:
                                                                  const Color(0xFF0D8B6E),
                                                              statusDot: connected
                                                                  ? AppColors
                                                                      .accentGreen
                                                                  : AppColors
                                                                      .accentRose,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: summaryWidth,
                                                            child: _SummaryCard(
                                                              title: 'Last Command',
                                                              value: _friendlyCommand(
                                                                control.lastCommand,
                                                              ),
                                                              subtitle:
                                                                  'Events: ${timeline.length}',
                                                              tone:
                                                                  const Color(0xFF161B30),
                                                              border:
                                                                  const Color(0xFF35436D),
                                                              statusDot:
                                                                  const Color(0xFF66779F),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height:
                                                            AppSpacing.section,
                                                      ),
                                                      Wrap(
                                                        spacing: AppSpacing.md,
                                                        runSpacing:
                                                            AppSpacing.md,
                                                        children: [
                                                          SizedBox(
                                                            width: systemWidth,
                                                            child: _SystemStateCard(
                                                              title: 'System',
                                                              value: connected
                                                                  ? 'Online'
                                                                  : 'Offline',
                                                              accent: connected
                                                                  ? AppColors
                                                                      .accentGreen
                                                                  : AppColors
                                                                      .accentRose,
                                                              icon: Icons
                                                                  .radar_rounded,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: systemWidth,
                                                            child: const _SystemStateCard(
                                                              title:
                                                                  'Data Source',
                                                              value:
                                                                  'Firebase RTDB',
                                                              accent: AppColors
                                                                  .accentCyan,
                                                              icon: Icons
                                                                  .cloud_done_rounded,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: systemWidth,
                                                            child: _SystemStateCard(
                                                              title: 'Mode',
                                                              value: _viewMode ==
                                                                      _ScadaViewMode
                                                                          .dashboard
                                                                  ? 'Live Monitoring'
                                                                  : 'Digital Twin',
                                                              accent: AppColors
                                                                  .accentOrange,
                                                              icon: Icons
                                                                  .hub_rounded,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: systemWidth,
                                                            child: _SystemStateCard(
                                                              title:
                                                                  'Last Update',
                                                              value: _formatClock(
                                                                liveData?.timestamp,
                                                              ),
                                                              accent: const Color(
                                                                  0xFF8AB4F8),
                                                              icon: Icons
                                                                  .schedule_rounded,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height:
                                                            AppSpacing.section,
                                                      ),
                                                      if (wide)
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              flex: 3,
                                                              child: leftRail,
                                                            ),
                                                            const SizedBox(
                                                              width:
                                                                  AppSpacing
                                                                      .section,
                                                            ),
                                                            SizedBox(
                                                              width: 348,
                                                              child: rightRail,
                                                            ),
                                                          ],
                                                        )
                                                      else ...[
                                                        leftRail,
                                                        const SizedBox(
                                                          height: AppSpacing
                                                              .section,
                                                        ),
                                                        rightRail,
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static List<_ScadaAlarm> _deriveAlarms({
    required SensorData? data,
    required bool connected,
  }) {
    final alarms = <_ScadaAlarm>[];

    if (!connected) {
      alarms.add(
        const _ScadaAlarm(
          title: 'Realtime connection lost',
          detail: 'Telemetry sync from Firebase is currently unavailable.',
          severity: _AlarmSeverity.critical,
        ),
      );
    }

    if (data == null) {
      if (connected) {
        alarms.add(
          const _ScadaAlarm(
            title: 'Waiting for live sensor payload',
            detail: 'The SCADA screen is online but no sensor snapshot has arrived yet.',
            severity: _AlarmSeverity.warning,
          ),
        );
      }
      return alarms;
    }

    if ((data.temperature ?? 0) >= 35) {
      alarms.add(
        _ScadaAlarm(
          title: 'Temperature above threshold',
          detail:
              'Current value ${data.temperature!.toStringAsFixed(1)} C exceeds the safe climate band.',
          severity: _AlarmSeverity.critical,
        ),
      );
    }

    if ((data.soilMoisture ?? 0) >= 2200) {
      alarms.add(
        _ScadaAlarm(
          title: 'Root zone is too dry',
          detail:
              'Soil moisture is ${data.soilMoisture!.toStringAsFixed(0)} and irrigation demand is rising.',
          severity: _AlarmSeverity.warning,
        ),
      );
    }

    if (data.humidity != null &&
        (data.humidity! < 35 || data.humidity! > 95)) {
      alarms.add(
        _ScadaAlarm(
          title: 'Humidity outside target range',
          detail:
              'Humidity is ${data.humidity!.toStringAsFixed(0)}%, which can affect crop stability.',
          severity: _AlarmSeverity.warning,
        ),
      );
    }

    if (data.lightLevel != null && data.lightLevel! < 100) {
      alarms.add(
        _ScadaAlarm(
          title: 'Light level too low',
          detail:
              'Canopy light exposure dropped to ${data.lightLevel!.toStringAsFixed(0)} lux.',
          severity: _AlarmSeverity.warning,
        ),
      );
    }

    if (data.waterLevelPercent != null && data.waterLevelPercent! < 20) {
      alarms.add(
        _ScadaAlarm(
          title: 'Water reserve low',
          detail:
              'Reservoir is at ${data.waterLevelPercent!.toStringAsFixed(0)}% and may constrain irrigation.',
          severity: _AlarmSeverity.critical,
        ),
      );
    }

    return alarms;
  }

  static List<_TimelineEntry> _buildTimeline({
    required List<ScadaEvent> scadaEvents,
    required List<NotificationModel> notifications,
  }) {
    final entries = <_TimelineEntry>[
      ...scadaEvents.map(
        (event) => _TimelineEntry(
          title: event.title,
          message: event.message,
          source: event.source,
          timestamp: event.timestamp,
          tone: switch (event.severity) {
            ScadaEventSeverity.success => AppColors.accentGreen,
            ScadaEventSeverity.warning => AppColors.accentOrange,
            ScadaEventSeverity.critical => AppColors.accentRose,
            ScadaEventSeverity.info => AppColors.accentCyan,
          },
          label: switch (event.severity) {
            ScadaEventSeverity.success => 'SUCCESS',
            ScadaEventSeverity.warning => 'WARNING',
            ScadaEventSeverity.critical => 'CRITICAL',
            ScadaEventSeverity.info => 'INFO',
          },
        ),
      ),
      ...notifications.take(10).map(
        (notification) => _TimelineEntry(
          title: notification.title,
          message: notification.message,
          source: notification.source,
          timestamp: notification.timestamp,
          tone: switch (notification.type) {
            NotificationType.success => AppColors.accentGreen,
            NotificationType.warning => AppColors.accentOrange,
            NotificationType.error => AppColors.accentRose,
            NotificationType.alert => AppColors.accentRose,
            NotificationType.info => AppColors.accentCyan,
          },
          label: notification.priority.name.toUpperCase(),
        ),
      ),
    ];

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(6).toList();
  }
}

class _ScadaHeader extends StatelessWidget {
  final _ScadaViewMode viewMode;
  final ValueChanged<_ScadaViewMode> onSelectView;

  const _ScadaHeader({
    required this.viewMode,
    required this.onSelectView,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF23D1FF),
      letterSpacing: -0.3,
    );
    final subtitleStyle = GoogleFonts.ibmPlexSans(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF95A9CB),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final stackToggles = constraints.maxWidth < 560;

        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 48 : 56,
              height: compact ? 48 : 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF163A68), Color(0xFF21C8F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF21C8F6).withValues(alpha: 0.25),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AgroSmart SCADA', style: titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Supervisory Control and Data Acquisition Interface',
                    style: subtitleStyle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _HeaderMetaChip(
                        label: 'Realtime control',
                        color: Color(0xFF1BCBEA),
                      ),
                      _HeaderMetaChip(
                        label: 'Mobile optimized',
                        color: Color(0xFF55D38A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final toggles = DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1730),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF25344F)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderToggleButton(
                  label: 'Dashboard',
                  selected: viewMode == _ScadaViewMode.dashboard,
                  onTap: () => onSelectView(_ScadaViewMode.dashboard),
                ),
                _HeaderToggleButton(
                  label: 'Digital Twin',
                  selected: viewMode == _ScadaViewMode.digitalTwin,
                  onTap: () => onSelectView(_ScadaViewMode.digitalTwin),
                ),
              ],
            ),
          ),
        );

        if (stackToggles) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppSpacing.lg),
              toggles,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppSpacing.md),
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: toggles,
              ),
          ],
        );
      },
    );
  }
}

class _HeaderToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HeaderToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF15264A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2B8FFF) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFFAFBEDC),
          ),
        ),
      ),
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderMetaChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color tone;
  final Color border;
  final Color statusDot;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.tone,
    required this.border,
    required this.statusDot,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.50),
            const Color(0xFF10182B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF95A6C3),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusDot,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: const Color(0xFF90A1BE),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SystemStateCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const _SystemStateCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF121A31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF20314E)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8FA5C7),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScadaPanel extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget child;

  const _ScadaPanel({
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10192E), Color(0xFF0D1426)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF18314A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ProcessOverview extends StatelessWidget {
  final SensorData? data;
  final ScadaControlState control;
  final bool connected;
  final List<_ScadaAlarm> alarms;

  const _ProcessOverview({
    required this.data,
    required this.control,
    required this.connected,
    required this.alarms,
  });

  @override
  Widget build(BuildContext context) {
    final anyCritical =
        alarms.any((alarm) => alarm.severity == _AlarmSeverity.critical);
    final nodes = [
      _ProcessNodeData(
        title: 'Water Source',
        state: data?.waterLevelPercent != null && data!.waterLevelPercent! < 20
            ? 'LOW'
            : 'ONLINE',
        description: data?.waterLevelPercent == null
            ? 'Reservoir synced'
            : 'Tank ${data!.waterLevelPercent!.toStringAsFixed(0)}% full',
        accent: data?.waterLevelPercent != null && data!.waterLevelPercent! < 20
            ? AppColors.accentRose
            : AppColors.accentGreen,
      ),
      _ProcessNodeData(
        title: 'Pump Unit',
        state: data?.pumpStatus == true ? 'ACTIVE' : 'IDLE',
        description:
            data?.pumpStatus == true ? 'Water flow enabled' : 'Standing by',
        accent:
            data?.pumpStatus == true ? AppColors.accentCyan : const Color(0xFFA3B2D1),
      ),
      _ProcessNodeData(
        title: 'Irrigation Line',
        state: control.autoMode ? 'AUTO' : 'MANUAL',
        description: control.autoMode
            ? 'Awaiting sensor demand'
            : 'Operator authority',
        accent: control.autoMode ? AppColors.accentCyan : AppColors.accentOrange,
      ),
      _ProcessNodeData(
        title: 'Field Zone',
        state: anyCritical ? 'ALERT' : 'NORMAL',
        description: anyCritical ? 'Operator review needed' : 'Within target band',
        accent: anyCritical ? AppColors.accentRose : AppColors.accentGreen,
      ),
      _ProcessNodeData(
        title: 'Sensor Node',
        state: connected ? 'HEALTHY' : 'OFFLINE',
        description: connected ? 'Operating normally' : 'Data link down',
        accent: connected ? AppColors.accentGreen : AppColors.accentRose,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _adaptiveColumns(
          constraints.maxWidth,
          minTileWidth: 150,
          maxColumns: 5,
        );
        final width = _tileWidth(constraints.maxWidth, columns);
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final node in nodes)
              SizedBox(
                width: width,
                child: _ProcessNodeCard(data: node),
              ),
          ],
        );
      },
    );
  }
}

class _ProcessNodeData {
  final String title;
  final String state;
  final String description;
  final Color accent;

  const _ProcessNodeData({
    required this.title,
    required this.state,
    required this.description,
    required this.accent,
  });
}

class _ProcessNodeCard extends StatelessWidget {
  final _ProcessNodeData data;

  const _ProcessNodeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: data.accent == AppColors.accentGreen ||
                data.accent == AppColors.accentCyan
            ? const Color(0xFF123040)
            : const Color(0xFF091122),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.accent.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: data.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: data.accent.withValues(alpha: 0.32)),
            ),
            child: Text(
              data.state,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: const Color(0xFF9DB1CF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorPanelGrid extends StatelessWidget {
  final SensorData? data;
  final bool connected;

  const _SensorPanelGrid({
    required this.data,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final panels = [
      _SensorPanelData(
        label: 'Temperature',
        value: data?.temperature == null
            ? '--'
            : '${data!.temperature!.toStringAsFixed(1)} C',
        status: _temperatureStatus(data?.temperature),
        accent: _temperatureAccent(data?.temperature),
      ),
      _SensorPanelData(
        label: 'Humidity',
        value:
            data?.humidity == null ? '--' : '${data!.humidity!.toStringAsFixed(0)} %',
        status: _humidityStatus(data?.humidity),
        accent: _humidityAccent(data?.humidity),
      ),
      _SensorPanelData(
        label: 'Soil Moisture',
        value: data?.soilMoisture == null
            ? '--'
            : data!.soilMoisture!.toStringAsFixed(0),
        status: _soilStatus(data?.soilMoisture),
        accent: _soilAccent(data?.soilMoisture),
      ),
      _SensorPanelData(
        label: 'Light Level',
        value: data?.lightLevel == null
            ? '--'
            : data!.lightLevel!.toStringAsFixed(0),
        status: _lightStatus(data?.lightLevel),
        accent: _lightAccent(data?.lightLevel),
      ),
      _SensorPanelData(
        label: 'Irrigation',
        value: data?.pumpStatus == true ? 'ON' : 'OFF',
        status: data?.pumpStatus == true ? 'Running' : 'Standby',
        accent:
            data?.pumpStatus == true ? AppColors.accentCyan : const Color(0xFF8A9BB8),
      ),
      _SensorPanelData(
        label: 'Signal',
        value: connected ? 'LIVE' : 'DROP',
        status: connected ? 'Realtime' : 'Offline',
        accent: connected ? AppColors.accentGreen : AppColors.accentRose,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _adaptiveColumns(
          constraints.maxWidth,
          minTileWidth: 170,
          maxColumns: 3,
        );
        final width = _tileWidth(constraints.maxWidth, columns);
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final panel in panels)
              SizedBox(
                width: width,
                child: _SensorPanelCard(data: panel),
              ),
          ],
        );
      },
    );
  }

  static String _temperatureStatus(double? value) {
    if (value == null) return 'Pending';
    if (value >= 35) return 'Critical';
    if (value >= 30) return 'Watch';
    return 'Normal';
  }

  static Color _temperatureAccent(double? value) {
    if (value == null) return const Color(0xFF8FA5C7);
    if (value >= 35) return AppColors.accentRose;
    if (value >= 30) return AppColors.accentOrange;
    return AppColors.accentGreen;
  }

  static String _humidityStatus(double? value) {
    if (value == null) return 'Pending';
    if (value < 35 || value > 95) return 'Alert';
    return 'Normal';
  }

  static Color _humidityAccent(double? value) {
    if (value == null) return const Color(0xFF8FA5C7);
    if (value < 35 || value > 95) return AppColors.accentOrange;
    return AppColors.accentGreen;
  }

  static String _soilStatus(double? value) {
    if (value == null) return 'Pending';
    if (value >= 2200) return 'Dry';
    if (value <= 1200) return 'Wet';
    return 'Normal';
  }

  static Color _soilAccent(double? value) {
    if (value == null) return const Color(0xFF8FA5C7);
    if (value >= 2200) return AppColors.accentOrange;
    return AppColors.accentGreen;
  }

  static String _lightStatus(double? value) {
    if (value == null) return 'Pending';
    if (value < 100) return 'Low';
    return 'Normal';
  }

  static Color _lightAccent(double? value) {
    if (value == null) return const Color(0xFF8FA5C7);
    if (value < 100) return AppColors.accentOrange;
    return AppColors.accentGreen;
  }
}

class _SensorPanelData {
  final String label;
  final String value;
  final String status;
  final Color accent;

  const _SensorPanelData({
    required this.label,
    required this.value,
    required this.status,
    required this.accent,
  });
}

class _SensorPanelCard extends StatelessWidget {
  final _SensorPanelData data;

  const _SensorPanelCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 158),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF060B18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3958)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF91A6C8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: data.accent.withValues(alpha: 0.36)),
            ),
            child: Text(
              data.status,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: data.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendGrid extends StatelessWidget {
  final List<SensorData> history;

  const _TrendGrid({required this.history});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MiniTrendCard(
        title: 'Temperature (C)',
        history: history,
        color: AppColors.accentOrange,
        selector: (sample) => sample.temperature,
      ),
      _MiniTrendCard(
        title: 'Humidity (%)',
        history: history,
        color: AppColors.accentCyan,
        selector: (sample) => sample.humidity,
      ),
      _MiniTrendCard(
        title: 'Soil Moisture',
        history: history,
        color: AppColors.accentGreen,
        selector: (sample) => sample.soilMoisture,
      ),
      _MiniTrendCard(
        title: 'Light Level',
        history: history,
        color: AppColors.accentPink,
        selector: (sample) => sample.lightLevel,
      ),
      _MiniTrendCard(
        title: 'Irrigation Activity',
        history: history,
        color: const Color(0xFF6EE7F9),
        selector: (sample) => sample.pumpStatus ? 1 : 0,
        decimals: 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _adaptiveColumns(
          constraints.maxWidth,
          minTileWidth: 300,
          maxColumns: 2,
        );
        final width = _tileWidth(constraints.maxWidth, columns);
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _MiniTrendCard extends StatelessWidget {
  final String title;
  final List<SensorData> history;
  final Color color;
  final num? Function(SensorData sample) selector;
  final int decimals;

  const _MiniTrendCard({
    required this.title,
    required this.history,
    required this.color,
    required this.selector,
    this.decimals = 1,
  });

  @override
  Widget build(BuildContext context) {
    final samples = history.reversed.take(12).toList().reversed.toList();
    final points = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < samples.length; i++) {
      final value = selector(samples[i]);
      if (value == null) continue;
      final number = value.toDouble();
      points.add(FlSpot(i.toDouble(), number));
      minY = math.min(minY, number);
      maxY = math.max(maxY, number);
    }

    final lastValue =
        points.isEmpty ? '--' : points.last.y.toStringAsFixed(decimals);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF060B18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3958)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Last ${points.length} samples',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8FA4C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for history',
                      style: GoogleFonts.ibmPlexSans(
                        color: const Color(0xFF8194B4),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: minY == maxY ? minY - 1 : minY - (maxY - minY) * 0.15,
                      maxY: minY == maxY ? maxY + 1 : maxY + (maxY - minY) * 0.15,
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xFF1E314A)),
                      ),
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFF18304C),
                          strokeWidth: 1,
                          dashArray: [4, 3],
                        ),
                        getDrawingVerticalLine: (_) => const FlLine(
                          color: Color(0xFF18304C),
                          strokeWidth: 1,
                          dashArray: [4, 3],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(decimals),
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 10,
                                color: const Color(0xFF8FA4C7),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: points.length > 1
                                ? math.max(1, (points.length - 1) / 2)
                                : 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= samples.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                DateFormat('HH:mm').format(samples[index].timestamp),
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  color: const Color(0xFF8FA4C7),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: points,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.18),
                                color.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              lastValue,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7FA7FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmPanel extends StatelessWidget {
  final List<_ScadaAlarm> alarms;

  const _AlarmPanel({required this.alarms});

  @override
  Widget build(BuildContext context) {
    return _ScadaPanel(
      title: 'Alarm Panel',
      accent: AppColors.accentRose,
      child: alarms.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF09111E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF31415D),
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                'No active alarms',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  color: const Color(0xFF9FB3D0),
                ),
              ),
            )
          : Column(
              children: [
                for (final alarm in alarms.take(3)) ...[
                  _AlarmTile(alarm: alarm),
                  if (alarm != alarms.take(3).last)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final _ScadaAlarm alarm;

  const _AlarmTile({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final color = switch (alarm.severity) {
      _AlarmSeverity.critical => AppColors.accentRose,
      _AlarmSeverity.warning => AppColors.accentOrange,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alarm.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            alarm.detail,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: const Color(0xFF96A8C5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  final FarmProfile profile;
  final CropRecommendation? recommendation;
  final bool loading;

  const _RecommendationPanel({
    required this.profile,
    required this.recommendation,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    String healthLabel;
    Color healthColor;

    final score = recommendation?.fitScore ?? 0;
    if (score >= 0.75) {
      healthLabel = 'GOOD';
      healthColor = AppColors.accentGreen;
    } else if (score >= 0.5) {
      healthLabel = 'FAIR';
      healthColor = AppColors.accentOrange;
    } else {
      healthLabel = 'POOR';
      healthColor = AppColors.accentRose;
    }

    return _ScadaPanel(
      title: 'AI Recommendation',
      accent: AppColors.accentGreen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF09111E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3958)),
        ),
        child: loading
            ? const SizedBox(
                height: 86,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : recommendation == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No farm profile loaded',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Add N, P, K and pH values to unlock crop-fit recommendations in the SCADA view.',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: const Color(0xFF99ABCA),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recommendation!.cropName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: healthColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: healthColor.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              healthLabel,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: healthColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        recommendation!.reason.isEmpty
                            ? 'Recommendation details are not available.'
                            : recommendation!.reason,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: const Color(0xFF99ABCA),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'N ${profile.n.toStringAsFixed(0)}  P ${profile.p.toStringAsFixed(0)}  K ${profile.k.toStringAsFixed(0)}  pH ${profile.ph.toStringAsFixed(1)}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF74D7FF),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _EventLogPanel extends StatelessWidget {
  final List<_TimelineEntry> timeline;

  const _EventLogPanel({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return _ScadaPanel(
      title: 'Event Log',
      accent: AppColors.accentCyan,
      child: timeline.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF09111E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A3958)),
              ),
              child: Text(
                'SCADA commands and notifications will appear here.',
                style: GoogleFonts.ibmPlexSans(
                  color: const Color(0xFF99ABCA),
                ),
              ),
            )
          : Column(
              children: [
                for (final entry in timeline.take(3)) ...[
                  _EventTile(entry: entry),
                  if (entry != timeline.take(3).last)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final _TimelineEntry entry;

  const _EventTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: entry.tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: entry.tone.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8FA5C7),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(entry.timestamp),
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: const Color(0xFFB9CCEA),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.message,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _InlineBadge(label: entry.label, color: entry.tone),
              const SizedBox(width: AppSpacing.sm),
              _InlineBadge(
                label: entry.source,
                color: const Color(0xFF5878B6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _InlineBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SupervisoryControlsPanel extends StatelessWidget {
  final ScadaControlState control;
  final SensorData? data;
  final bool busy;
  final int activeAlarms;
  final VoidCallback onAutoMode;
  final VoidCallback onManualMode;
  final VoidCallback onPumpOn;
  final VoidCallback onPumpOff;
  final VoidCallback onResetAlarms;

  const _SupervisoryControlsPanel({
    required this.control,
    required this.data,
    required this.busy,
    required this.activeAlarms,
    required this.onAutoMode,
    required this.onManualMode,
    required this.onPumpOn,
    required this.onPumpOff,
    required this.onResetAlarms,
  });

  @override
  Widget build(BuildContext context) {
    return _ScadaPanel(
      title: 'Supervisory Controls',
      accent: AppColors.accentOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InlineBadge(
                label: control.autoMode ? 'MODE: AUTO' : 'MODE: MANUAL',
                color:
                    control.autoMode ? AppColors.accentCyan : AppColors.accentOrange,
              ),
              _InlineBadge(
                label: 'Last command: ${_friendlyCommand(control.lastCommand)}',
                color: const Color(0xFF7088B5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 360;
              final pumpOnButton = _ControlButton(
                label: 'Pump ON',
                enabled: !busy && !control.autoMode,
                onTap: onPumpOn,
              );
              final pumpOffButton = _ControlButton(
                label: 'Pump OFF',
                enabled: !busy && !control.autoMode,
                onTap: onPumpOff,
              );
              final modeButton = _ActionButton(
                label: control.autoMode ? 'Switch to MANUAL' : 'Switch to AUTO',
                accent: AppColors.accentCyan,
                onTap: busy
                    ? null
                    : control.autoMode
                        ? onManualMode
                        : onAutoMode,
              );
              final alarmButton = _ActionButton(
                label: activeAlarms > 0 ? 'Reset Alarms' : 'Acknowledge',
                accent: AppColors.accentOrange,
                onTap: busy ? null : onResetAlarms,
              );

              if (stacked) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: pumpOnButton),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(width: double.infinity, child: pumpOffButton),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(width: double.infinity, child: modeButton),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(width: double.infinity, child: alarmButton),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: pumpOnButton),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: pumpOffButton),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: modeButton),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: alarmButton),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data?.pumpStatus == true
                ? 'Pump is currently running. Manual commands stay disabled while AUTO is active.'
                : 'Send direct pump commands only in MANUAL mode. AUTO preserves sensor-driven control.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: const Color(0xFF96A8C5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF1A243C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF31405D)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8EA1C3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.70)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent == AppColors.accentOrange
                  ? const Color(0xFFFFD970)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DigitalTwinBoard extends StatelessWidget {
  final SensorData? data;
  final ScadaControlState control;
  final bool connected;
  final List<_ScadaAlarm> alarms;

  const _DigitalTwinBoard({
    required this.data,
    required this.control,
    required this.connected,
    required this.alarms,
  });

  @override
  Widget build(BuildContext context) {
    final twinNodes = [
      ('Source', Alignment.centerLeft, data?.waterLevelPercent != null &&
              data!.waterLevelPercent! < 20
          ? AppColors.accentRose
          : AppColors.accentGreen),
      ('Pump', const Alignment(-0.35, -0.25),
          data?.pumpStatus == true ? AppColors.accentCyan : const Color(0xFF7D8DAF)),
      ('Controller', Alignment.center, control.autoMode
          ? AppColors.accentCyan
          : AppColors.accentOrange),
      ('Zone', const Alignment(0.4, -0.22),
          alarms.isNotEmpty ? AppColors.accentOrange : AppColors.accentGreen),
      ('Sensors', Alignment.centerRight,
          connected ? AppColors.accentGreen : AppColors.accentRose),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF07101D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF21324E)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final boardHeight = compact ? 220.0 : 260.0;
              return SizedBox(
                height: boardHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TwinLinesPainter(
                          accent: control.autoMode
                              ? AppColors.accentCyan
                              : AppColors.accentOrange,
                        ),
                      ),
                    ),
                    for (final node in twinNodes)
                      Align(
                        alignment: node.$2,
                        child: _TwinNode(
                          label: node.$1,
                          color: node.$3,
                          compact: compact,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _adaptiveColumns(
                constraints.maxWidth,
                minTileWidth: 150,
                maxColumns: 3,
              );
              final width = _tileWidth(constraints.maxWidth, columns);
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: width,
                    child: _TwinStat(
                      label: 'Flow State',
                      value: data?.pumpStatus == true ? 'Delivering' : 'Idle',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _TwinStat(
                      label: 'Control',
                      value: control.autoMode ? 'Closed loop' : 'Operator loop',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _TwinStat(
                      label: 'Alarm Pressure',
                      value: alarms.isEmpty ? 'Stable' : '${alarms.length} active',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TwinNode extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const _TwinNode({
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 72 : 86,
      height: compact ? 72 : 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.30),
            const Color(0xFF07101D),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.80)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TwinStat extends StatelessWidget {
  final String label;
  final String value;

  const _TwinStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF263651)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8FA5C7),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwinLinesPainter extends CustomPainter {
  final Color accent;

  const _TwinLinesPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.55);

    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF31527D);

    final center = Offset(size.width / 2, size.height / 2);
    final left = Offset(56, size.height / 2);
    final right = Offset(size.width - 56, size.height / 2);
    final upperLeft = Offset(size.width * 0.30, size.height * 0.28);
    final upperRight = Offset(size.width * 0.72, size.height * 0.30);

    canvas.drawLine(left, center, paint);
    canvas.drawLine(center, right, paint);
    canvas.drawLine(upperLeft, center, dashed);
    canvas.drawLine(center, upperRight, dashed);
  }

  @override
  bool shouldRepaint(covariant _TwinLinesPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _ScadaAlarm {
  final String title;
  final String detail;
  final _AlarmSeverity severity;

  const _ScadaAlarm({
    required this.title,
    required this.detail,
    required this.severity,
  });
}

enum _AlarmSeverity {
  warning,
  critical,
}

class _TimelineEntry {
  final String title;
  final String message;
  final String source;
  final DateTime timestamp;
  final Color tone;
  final String label;

  const _TimelineEntry({
    required this.title,
    required this.message,
    required this.source,
    required this.timestamp,
    required this.tone,
    required this.label,
  });
}

double _tileWidth(double totalWidth, int columns) {
  const spacing = AppSpacing.md;
  final safeColumns = math.max(1, columns);
  return (totalWidth - (spacing * (safeColumns - 1))) / safeColumns;
}

int _adaptiveColumns(
  double width, {
  required double minTileWidth,
  required int maxColumns,
}) {
  final estimated = ((width + AppSpacing.md) / (minTileWidth + AppSpacing.md))
      .floor();
  return math.max(1, math.min(maxColumns, estimated));
}

String _friendlyCommand(String raw) {
  switch (raw) {
    case 'MODE_AUTO':
      return 'AUTO';
    case 'MODE_MANUAL':
      return 'MANUAL';
    case 'PUMP_ON':
      return 'PUMP ON';
    case 'PUMP_OFF':
      return 'PUMP OFF';
    case 'RESET_ALARMS':
      return 'RESET';
    case 'NONE':
    case '':
      return '--';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String _formatClock(DateTime? timestamp) {
  if (timestamp == null) return '--:--:--';
  return DateFormat('HH:mm:ss').format(timestamp);
}
