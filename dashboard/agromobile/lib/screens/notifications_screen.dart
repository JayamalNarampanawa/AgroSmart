import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: NotificationService.instance.markAllAsRead,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Clear read',
            onPressed: NotificationService.instance.clearRead,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050A14),
              Color(0xFF0B1221),
              Color(0xFF050A14),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 12),
                _buildFilterCard(),
                const SizedBox(height: 12),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCount,
      builder: (context, unread, _) {
        return ValueListenableBuilder<List<NotificationModel>>(
          valueListenable: NotificationService.instance.notifications,
          builder: (context, notifications, __) {
            return GlassCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unread unread',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${notifications.length} total',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: NotificationService.instance.addTestNotification,
                    icon: const Icon(Icons.add_alert),
                    label: const Text('Test'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterCard() {
    return GlassCard(
      child: Row(
        children: [
          const Text(
            'Show unread only',
            style: TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          Switch(
            value: _showUnreadOnly,
            onChanged: (value) {
              setState(() => _showUnreadOnly = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ValueListenableBuilder<List<NotificationModel>>(
      valueListenable: NotificationService.instance.notifications,
      builder: (context, notifications, _) {
        final filtered = _showUnreadOnly
            ? notifications.where((n) => !n.isRead).toList()
            : notifications;

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'No notifications found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationTile(notification: filtered[index]),
            );
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    return GlassCard(
      onTap: () => NotificationService.instance.markAsRead(notification.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(notification.type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              notification.isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('MMM d, h:mm a').format(notification.timestamp),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.error:
      case NotificationType.alert:
        return const Color(0xFFFF5252);
      case NotificationType.warning:
        return const Color(0xFFFFC107);
      case NotificationType.success:
        return const Color(0xFF00FFC2);
      case NotificationType.info:
        return const Color(0xFF00E5FF);
    }
  }

  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.error:
        return Icons.error;
      case NotificationType.alert:
        return Icons.warning_amber;
      case NotificationType.warning:
        return Icons.info;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.info:
        return Icons.notifications;
    }
  }
}
