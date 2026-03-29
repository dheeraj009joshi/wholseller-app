import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';

/// Notifications screen - shows order updates, offers, etc.
/// Backend notifications API can be integrated later.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Placeholder - can integrate with notifications API later
    setState(() {
      _notifications = [
        {'id': '1', 'title': 'Welcome!', 'body': 'Thanks for using our medical store app.', 'time': 'Just now', 'read': false},
        {'id': '2', 'title': 'Order Update', 'body': 'Your order has been confirmed.', 'time': '2 hours ago', 'read': true},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _notifications.clear()),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, i) {
                  final n = _notifications[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (n['read'] == true ? Colors.grey : AppTheme.primaryColor).withOpacity(0.2),
                        child: Icon(Icons.notifications, color: n['read'] == true ? Colors.grey : AppTheme.primaryColor),
                      ),
                      title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(n['body'] ?? ''),
                      trailing: Text(n['time'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
