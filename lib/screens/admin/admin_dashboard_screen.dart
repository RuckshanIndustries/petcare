import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petcare/screens/admin/AppointmentDetailsScreen.dart';
import 'package:petcare/screens/admin/reports_screen.dart';
import 'package:petcare/screens/admin/manage_vets_screen.dart';


import '../common/profile_screen.dart';
import '../common/notifications_screen.dart';
import '../common/reusable_bottom_tab_bar.dart';
import '../common/settings_screen.dart';
import 'billing_screen_admin.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildDashboard(),
                NotificationsScreen(),
                SettingsScreen(),
                ProfileScreen(),


              ],
            ),
          ),
          ReusableBottomTabBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildInfoCard('Total Revenue', 'billings', 'amount', isMoney: true),
              _buildInfoCard('Total Appointments', 'appointments', '', isClickable: true),
              _buildInfoCard('Total Users', 'users', ''),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Veterinarians',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageVetsScreen()),
                  );
                },
                child: Text(
                  'Manage',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            height: 120,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'Veterinarian')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var vets = snapshot.data!.docs;
                if (vets.isEmpty) {
                  return Center(
                    child: Text(
                      'No veterinarians found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: vets.length,
                  itemBuilder: (context, index) {
                    var vet = vets[index];
                    return Container(
                      width: 150,
                      margin: EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageVetsScreen(),
                            ),
                          );
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF9800),
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        vet['name'],
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  vet['specialty'] ?? 'No Specialty',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportsScreen()),
              );
            },
            child: Text('Generate Reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String collection, String field, {bool isMoney = false, bool isClickable = false}) {
    return GestureDetector(
      onTap: isClickable
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppointmentDetailsScreen()),
        );
      }
          : null,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 28,
                color: Theme.of(context).textTheme.titleMedium!.color,
              ),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 5),
              FutureBuilder<QuerySnapshot>(
                future: _firestore.collection(collection).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  double total = 0;
                  if (field.isNotEmpty) {
                    snapshot.data!.docs.forEach((doc) {
                      total += doc[field];
                    });
                  }
                  return Text(
                    isMoney ? '\$${total.toStringAsFixed(2)}' : '${snapshot.data!.docs.length}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 22),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}