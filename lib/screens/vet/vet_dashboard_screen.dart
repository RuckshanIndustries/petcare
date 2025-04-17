import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../common/reusable_bottom_tab_bar.dart';
import '../common/settings_screen.dart';
import 'appointment_details_screen.dart';

class VetDashboardScreen extends StatefulWidget {
  @override
  _VetDashboardScreenState createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 0) {
        _pageController.jumpToPage(index - 1); // Adjust index for PageView
      }
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date); // e.g., "10:48 am"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Veterinarian Dashboard'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Always keep PageView in the widget tree
          IndexedStack(
            index: _selectedIndex == 0 ? 1 : 0,
            children: [
              PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  NotificationsScreen(),
                  SettingsScreen(),
                  ProfileScreen(),
                ],
              ),
              // StreamBuilder for displaying appointments
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('appointments')
                    .where('vetId', isEqualTo: _auth.currentUser?.uid ?? '')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('No data available'));
                  }

                  var appointments = snapshot.data!.docs;
                  if (appointments.isEmpty) {
                    return Center(
                      child: Text(
                        'No appointments found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: appointments.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) {
                      var appointment = appointments[index];
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
                              Icons.calendar_today, // Placeholder icon
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          appointment['type'] ?? 'Appointment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['description'] ?? 'Details not provided',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 4),
                            Text(
                              appointment['date'] != null
                                  ? _formatTimestamp(appointment['date'])
                                  : 'Date not set',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailsScreen(
                                appointmentId: appointment.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          // Reusable Bottom Tab Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ReusableBottomTabBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}