import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../widgets/notification_panel.dart';

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  bool _showPanel = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            setState(() {
              _showPanel = true;
            });
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: NotificationService.instance.unreadCount,
          builder: (context, count, _) {
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
        if (_showPanel)
          Positioned.fill(
            child: NotificationPanel(
              onClose: () {
                setState(() {
                  _showPanel = false;
                });
              },
            ),
          ),
      ],
    );
  }
}
