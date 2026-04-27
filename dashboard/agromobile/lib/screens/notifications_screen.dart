import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: ValueListenableBuilder<List<NotificationModel>>(
        valueListenable: NotificationService.instance.notifications,
        builder: (context, notifications, _) {
          final unread = notifications.where((item) => !item.isRead).length;
          final filtered = _showUnreadOnly
              ? notifications.where((item) => !item.isRead).toList()
              : notifications;

          return ListView(
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
                greeting: 'Notifications',
                subtitle: 'Realtime alerts and system activity',
                avatarText: 'N',
              ),
              const SizedBox(height: AppSpacing.section),
              _NotificationHero(
                total: notifications.length,
                unread: unread,
                critical: notifications
                    .where(
                      (item) =>
                          item.priority == NotificationPriority.critical ||
                          item.type == NotificationType.alert ||
                          item.type == NotificationType.error,
                    )
                    .length,
              ),
              const SizedBox(height: AppSpacing.sectionLarge),
              SectionHeader(
                title: 'Inbox Controls',
                subtitle: _showUnreadOnly
                    ? 'Showing unread messages only'
                    : 'Showing every stored notification',
                actionText: notifications.isEmpty ? null : 'Read all',
                actionIcon: Icons.done_all_rounded,
                onAction: notifications.isEmpty
                    ? null
                    : NotificationService.instance.markAllAsRead,
              ),
              const SizedBox(height: AppSpacing.lg),
              _FilterCard(
                showUnreadOnly: _showUnreadOnly,
                unread: unread,
                onChanged: (value) => setState(() => _showUnreadOnly = value),
                onClearRead: NotificationService.instance.clearRead,
                onClearAll: NotificationService.instance.clearAll,
                hasNotifications: notifications.isNotEmpty,
              ),
              const SizedBox(height: AppSpacing.sectionLarge),
              SectionHeader(
                title: 'Recent Alerts',
                subtitle: filtered.isEmpty
                    ? 'No notifications match this filter'
                    : '${filtered.length} notification${filtered.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                const SoftWhiteCard(
                  child: EmptyStateWidget(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications found',
                    subtitle:
                        'Live sensor alerts, login activity, forecast events, and system messages will appear here.',
                  ),
                )
              else
                ...filtered.map(
                  (notification) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _NotificationTile(notification: notification),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationHero extends StatelessWidget {
  final int total;
  final int unread;
  final int critical;

  const _NotificationHero({
    required this.total,
    required this.unread,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
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
                  Icons.notifications_active_rounded,
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
                      '$unread unread',
                      style: theme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$total total notifications in this device',
                      style: theme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(label: 'Unread', value: unread.toString()),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child:
                    _HeroMetric(label: 'Critical', value: critical.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
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
            style: theme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final bool showUnreadOnly;
  final int unread;
  final ValueChanged<bool> onChanged;
  final VoidCallback onClearRead;
  final VoidCallback onClearAll;
  final bool hasNotifications;

  const _FilterCard({
    required this.showUnreadOnly,
    required this.unread,
    required this.onChanged,
    required this.onClearRead,
    required this.onClearAll,
    required this.hasNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftWhiteCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(
                  Icons.filter_alt_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unread filter', style: theme.bodyLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$unread unread notification${unread == 1 ? '' : 's'}',
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: showUnreadOnly,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasNotifications ? onClearRead : null,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear read'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white70 : AppColors.textPrimary,
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.borderSoft,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasNotifications ? onClearAll : null,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Clear all'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    final theme = Theme.of(context).textTheme;

    return Stack(
      children: [
        SoftWhiteCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: InkWell(
            onTap: () =>
                NotificationService.instance.markAsRead(notification.id),
            borderRadius: AppRadius.cardRadius,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Icon(_iconFor(notification.type), color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleMedium?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        notification.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(
                            label: notification.source,
                            tone: _toneFor(notification.type),
                          ),
                          StatusBadge(
                            label: notification.priority.name.toUpperCase(),
                            tone: _priorityTone(notification.priority),
                          ),
                          StatusBadge(
                            label: DateFormat('MMM d, h:mm a')
                                .format(notification.timestamp),
                            tone: StatusBadgeTone.neutral,
                            icon: Icons.schedule_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 18,
          bottom: 18,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }

  static Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.error:
      case NotificationType.alert:
        return AppColors.accentRose;
      case NotificationType.warning:
        return AppColors.accentOrange;
      case NotificationType.success:
        return AppColors.accentGreen;
      case NotificationType.info:
        return AppColors.accentCyan;
    }
  }

  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
      case NotificationType.warning:
        return Icons.info_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.info:
        return Icons.notifications_rounded;
    }
  }

  static StatusBadgeTone _toneFor(NotificationType type) {
    switch (type) {
      case NotificationType.error:
      case NotificationType.alert:
        return StatusBadgeTone.error;
      case NotificationType.warning:
        return StatusBadgeTone.warning;
      case NotificationType.success:
        return StatusBadgeTone.success;
      case NotificationType.info:
        return StatusBadgeTone.info;
    }
  }

  static StatusBadgeTone _priorityTone(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
      case NotificationPriority.high:
        return StatusBadgeTone.error;
      case NotificationPriority.normal:
        return StatusBadgeTone.info;
      case NotificationPriority.low:
        return StatusBadgeTone.neutral;
    }
  }
}
