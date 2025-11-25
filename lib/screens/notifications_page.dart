import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      const _NotificationData(
        title: 'Document ready for pickup',
        body: 'Your Barangay Clearance can be collected today.',
        timestamp: '2h ago',
        tag: 'New',
        color: Color(0xFF30C38C),
      ),
      const _NotificationData(
        title: 'Payment due tomorrow',
        body: 'Community Tax Certificate needs payment by noon.',
        timestamp: '1d ago',
        tag: 'Due Soon',
        color: Color(0xFFF5A524),
      ),
      const _NotificationData(
        title: 'Community Clean-Up',
        body: 'Reminder: assembly at Barangay Hall, 7AM Saturday.',
        timestamp: '3d ago',
        tag: 'Event',
        color: Color(0xFF5E54FF),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              leading: CircleAvatar(
                backgroundColor: item.color.withOpacity(0.15),
                child: Icon(Icons.notifications, color: item.color),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(item.body),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          item.tag,
                          style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.timestamp,
                        style: const TextStyle(
                          color: Color(0xFF9AA3B9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationData {
  const _NotificationData({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.tag,
    required this.color,
  });

  final String title;
  final String body;
  final String timestamp;
  final String tag;
  final Color color;
}

