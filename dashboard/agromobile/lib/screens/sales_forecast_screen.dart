import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/notification_model.dart';
import '../models/sales_forecast.dart';
import '../services/notification_service.dart';
import '../services/sales_forecast_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class SalesForecastScreen extends StatefulWidget {
  const SalesForecastScreen({super.key});

  @override
  State<SalesForecastScreen> createState() => _SalesForecastScreenState();
}

class _SalesForecastScreenState extends State<SalesForecastScreen> {
  static const _categories = ['Grocery', 'Electronics', 'Fashion', 'Home'];
  static const _regions = ['North', 'South', 'East', 'West'];
  static const _stores = ['Store A', 'Store B', 'Store C', 'Online'];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  String _category = _categories.first;
  String _region = _regions.first;
  String _store = _stores.first;
  bool _promoFlag = false;
  bool _isLoading = false;
  SalesForecastResponse? _forecast;
  String? _error;

  final _currency = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
  final _shortDate = DateFormat('MMM d');

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.cardDark,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: AppColors.cardWhite,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<void> _predict() async {
    if (_endDate.difference(_startDate).inDays > 90) {
      setState(() {
        _error = 'Please keep the forecast range within 90 days.';
      });
      NotificationService.instance.addNotification(
        title: 'Forecast Range Too Long',
        message:
            'Sales forecast request was blocked because the range exceeded 90 days.',
        type: NotificationType.warning,
        priority: NotificationPriority.normal,
        source: 'Sales Forecast',
        duplicateWindow: const Duration(seconds: 10),
      );
      return;
    }

    final request = SalesForecastRequest(
      startDate: _startDate,
      endDate: _endDate,
      productCategory: _category,
      region: _region,
      store: _store,
      promoFlag: _promoFlag,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });
    NotificationService.instance.addNotification(
      title: 'Sales Forecast Started',
      message:
          'Forecasting $_category sales for $_region / $_store from ${_shortDate.format(_startDate)} to ${_shortDate.format(_endDate)}.',
      type: NotificationType.info,
      priority: NotificationPriority.low,
      source: 'Sales Forecast',
      duplicateWindow: const Duration(seconds: 10),
    );

    try {
      final response = await SalesForecastApiService.instance.predict(request);
      if (!mounted) return;
      setState(() {
        _forecast = response;
        _isLoading = false;
      });
      NotificationService.instance.addNotification(
        title: response.isDemo
            ? 'Demo Forecast Generated'
            : 'Sales Forecast Ready',
        message:
            '${response.modelName} predicted ${_currency.format(response.totalPredictedSales)} total sales.',
        type: response.isDemo
            ? NotificationType.warning
            : NotificationType.success,
        priority: response.isDemo
            ? NotificationPriority.normal
            : NotificationPriority.high,
        source: 'Sales Forecast',
        showSystemAlert: !response.isDemo,
        duplicateWindow: const Duration(seconds: 10),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Forecast failed: $e';
        _isLoading = false;
      });
      NotificationService.instance.addNotification(
        title: 'Sales Forecast Failed',
        message: 'The sales forecasting request failed: $e',
        type: NotificationType.error,
        priority: NotificationPriority.high,
        source: 'Sales Forecast',
        showSystemAlert: true,
        duplicateWindow: const Duration(seconds: 10),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _endDate.difference(_startDate).inDays + 1;

    return AppScaffold(
      bottomInset: 110,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.sectionLarge,
        ),
        children: [
          const DashboardHeader(
            leading: SizedBox(width: 36, height: 44),
            greeting: 'Sales Forecast',
            subtitle: 'Predict demand with the tuned ML model',
            avatarText: 'F',
          ),
          const SizedBox(height: AppSpacing.section),
          _ForecastHero(
            category: _category,
            region: _region,
            store: _store,
            days: days,
            promoFlag: _promoFlag,
            forecast: _forecast,
            currency: _currency,
          ),
          const SizedBox(height: AppSpacing.sectionLarge),
          const SectionHeader(
            title: 'Forecast Inputs',
            subtitle: 'Choose the scenario for the demand forecast',
          ),
          const SizedBox(height: AppSpacing.lg),
          _InputCard(
            startDate: _startDate,
            endDate: _endDate,
            category: _category,
            region: _region,
            store: _store,
            promoFlag: _promoFlag,
            categories: _categories,
            regions: _regions,
            stores: _stores,
            shortDate: _shortDate,
            onPickStart: () => _pickDate(isStart: true),
            onPickEnd: () => _pickDate(isStart: false),
            onCategoryChanged: (value) => setState(() => _category = value),
            onRegionChanged: (value) => setState(() => _region = value),
            onStoreChanged: (value) => setState(() => _store = value),
            onPromoChanged: (value) => setState(() => _promoFlag = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PredictButton(
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _predict,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AlertCard(
              icon: Icons.error_outline_rounded,
              title: 'Forecast failed',
              message: _error!,
              color: AppColors.accentRose,
              tone: StatusBadgeTone.error,
              timestamp: 'Error',
            ),
          ],
          if (_forecast != null) ...[
            const SizedBox(height: AppSpacing.sectionLarge),
            SectionHeader(
              title: 'Forecast Result',
              subtitle: _forecast!.isDemo
                  ? 'Demo baseline shown because the API is unavailable'
                  : 'FastAPI model response received',
              actionText: _forecast!.isDemo ? 'Demo' : 'ML',
              actionIcon: _forecast!.isDemo
                  ? Icons.info_outline_rounded
                  : Icons.check_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SummaryCards(forecast: _forecast!, currency: _currency),
            const SizedBox(height: AppSpacing.lg),
            _ForecastChart(points: _forecast!.forecast, currency: _currency),
            const SizedBox(height: AppSpacing.lg),
            _HistoricalComparison(
              points: _forecast!.forecast,
              metrics: _forecast!.metrics,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModelNotes(forecast: _forecast!),
          ],
        ],
      ),
    );
  }
}

class _ForecastHero extends StatelessWidget {
  final String category;
  final String region;
  final String store;
  final int days;
  final bool promoFlag;
  final SalesForecastResponse? forecast;
  final NumberFormat currency;

  const _ForecastHero({
    required this.category,
    required this.region,
    required this.store,
    required this.days,
    required this.promoFlag,
    required this.forecast,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final total = forecast == null
        ? 'Ready'
        : currency.format(forecast!.totalPredictedSales);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.violetCyanGradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coursework Forecasting',
                      style: theme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$category demand for $region / $store',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            total,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            forecast == null
                ? 'Select inputs and predict sales'
                : 'Total forecast',
            style: theme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroChip(label: 'Range', value: '$days days'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeroChip(
                  label: 'Promo',
                  value: promoFlag ? 'Active' : 'Off',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final String region;
  final String store;
  final bool promoFlag;
  final List<String> categories;
  final List<String> regions;
  final List<String> stores;
  final DateFormat shortDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onStoreChanged;
  final ValueChanged<bool> onPromoChanged;

  const _InputCard({
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.region,
    required this.store,
    required this.promoFlag,
    required this.categories,
    required this.regions,
    required this.stores,
    required this.shortDate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCategoryChanged,
    required this.onRegionChanged,
    required this.onStoreChanged,
    required this.onPromoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SoftWhiteCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Start',
                  value: shortDate.format(startDate),
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateTile(
                  label: 'End',
                  value: shortDate.format(endDate),
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DropdownTile(
            label: 'Product Category',
            value: category,
            values: categories,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _DropdownTile(
                  label: 'Region',
                  value: region,
                  values: regions,
                  onChanged: onRegionChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DropdownTile(
                  label: 'Store',
                  value: store,
                  values: stores,
                  onChanged: onStoreChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PromoSwitch(value: promoFlag, onChanged: onPromoChanged),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month_rounded, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: isDark ? AppColors.cardDark : AppColors.cardWhite,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _PromoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PromoSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: AppColors.accentOrange,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promotion active', style: theme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Include uplift from discounts or campaigns',
                  style: theme.bodyMedium,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PredictButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PredictButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: AppColors.violetCyanGradient),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow:
                onPressed == null ? [] : AppShadows.softGlow(AppColors.primary),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: Colors.white),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Predict Sales',
                        style: theme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final SalesForecastResponse forecast;
  final NumberFormat currency;

  const _SummaryCards({
    required this.forecast,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricCard(
          label: 'Total Forecast',
          value: currency.format(forecast.totalPredictedSales),
          icon: Icons.payments_rounded,
          color: AppColors.accentGreen,
        ),
        const SizedBox(height: AppSpacing.md),
        _MetricCard(
          label: 'Daily Average',
          value: currency.format(forecast.averageDailySales),
          icon: Icons.today_rounded,
          color: AppColors.accentCyan,
        ),
        const SizedBox(height: AppSpacing.md),
        _MetricCard(
          label: 'Confidence Range',
          value:
              '${currency.format(forecast.confidenceLow)} - ${currency.format(forecast.confidenceHigh)}',
          icon: Icons.stacked_line_chart_rounded,
          color: AppColors.accentOrange,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  final List<SalesForecastPoint> points;
  final NumberFormat currency;

  const _ForecastChart({
    required this.points,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SoftWhiteCard(
      title: 'Forecast Trend',
      subtitle: 'Predicted sales across the selected range',
      child: SizedBox(
        height: 260,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: DateTimeAxis(
            labelStyle: _axisStyle(context),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            labelStyle: _axisStyle(context),
            axisLabelFormatter: (details) {
              return ChartAxisLabel(
                currency.format(details.value),
                details.textStyle,
              );
            },
            majorGridLines: MajorGridLines(
              color: AppColors.borderSoft.withValues(alpha: 0.55),
            ),
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <CartesianSeries<SalesForecastPoint, DateTime>>[
            SplineAreaSeries<SalesForecastPoint, DateTime>(
              dataSource: points,
              xValueMapper: (point, _) => point.date,
              yValueMapper: (point, _) => point.predictedSales,
              color: AppColors.primary.withValues(alpha: 0.16),
              borderColor: AppColors.primary,
              borderWidth: 3,
              name: 'Predicted',
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoricalComparison extends StatelessWidget {
  final List<SalesForecastPoint> points;
  final Map<String, double> metrics;

  const _HistoricalComparison({
    required this.points,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final comparisonPoints =
        points.where((point) => point.actualSales != null).toList();

    return SoftWhiteCard(
      title: 'Historical Comparison',
      subtitle: 'Predicted and actual lines from known samples',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comparisonPoints.isEmpty)
            Text(
              'Historical actual values are not available for this range.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            SizedBox(
              height: 240,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  labelStyle: _axisStyle(context),
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: _axisStyle(context),
                  majorGridLines: MajorGridLines(
                    color: AppColors.borderSoft.withValues(alpha: 0.55),
                  ),
                ),
                legend: Legend(
                  isVisible: true,
                  textStyle: _axisStyle(context),
                ),
                series: <CartesianSeries<SalesForecastPoint, DateTime>>[
                  LineSeries<SalesForecastPoint, DateTime>(
                    dataSource: comparisonPoints,
                    xValueMapper: (point, _) => point.date,
                    yValueMapper: (point, _) => point.predictedSales,
                    color: AppColors.primary,
                    width: 3,
                    name: 'Predicted',
                  ),
                  LineSeries<SalesForecastPoint, DateTime>(
                    dataSource: comparisonPoints,
                    xValueMapper: (point, _) => point.date,
                    yValueMapper: (point, _) => point.actualSales,
                    color: AppColors.accentOrange,
                    width: 3,
                    name: 'Actual',
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ScoreChip(label: 'RMSE', value: metrics['rmse']),
              _ScoreChip(label: 'MAE', value: metrics['mae']),
              _ScoreChip(label: 'MAPE', value: metrics['mape'], suffix: '%'),
              _ScoreChip(label: 'R2', value: metrics['r2']),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final double? value;
  final String suffix;

  const _ScoreChip({
    required this.label,
    required this.value,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label:
          '$label ${value == null ? '--' : value!.toStringAsFixed(2)}$suffix',
      tone: StatusBadgeTone.info,
    );
  }
}

class _ModelNotes extends StatelessWidget {
  final SalesForecastResponse forecast;

  const _ModelNotes({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return AlertCard(
      icon: forecast.isDemo
          ? Icons.info_outline_rounded
          : Icons.check_circle_rounded,
      title: forecast.modelName,
      message: forecast.note ?? 'FastAPI model response received successfully.',
      color: forecast.isDemo ? AppColors.accentOrange : AppColors.accentGreen,
      tone: forecast.isDemo ? StatusBadgeTone.warning : StatusBadgeTone.success,
      timestamp: forecast.isDemo ? 'Demo' : 'Live',
    );
  }
}

TextStyle _axisStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    color: isDark ? Colors.white60 : AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
