import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to fetch notifications for the current user
  Stream<QuerySnapshot> _getNotificationsStream() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('timestamp', descending: true) // Newest first
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              var notification = notifications[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fastfood, // Placeholder for food dispenser icon
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                title: Text(
                  notification['title'] ?? 'Notification',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  notification['body'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
                onTap: () {
                  // Handle tap based on notification type
                  String? type = notification['type'];
                  if (type == 'food') {
                    // Navigate to food management screen (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to food management screen')),
                    );
                  } else if (type == 'mood') {
                    // Navigate to pet status screen (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to pet status screen')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}