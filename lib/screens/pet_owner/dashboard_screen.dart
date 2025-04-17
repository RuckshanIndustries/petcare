import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petcare/screens/common/profile_screen.dart';
import '../common/notifications_screen.dart';
import '../common/reusable_bottom_tab_bar.dart';
import '../common/settings_screen.dart';
import 'pet_profile_screen.dart';
import 'appointment_screen.dart';
import 'billing_screen.dart';

// Placeholder screens for navigation
class DiscoverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Discover Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class ExploreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Explore Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class ManageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Manage Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pet Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PetProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildPetsList(),
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

  Widget _buildPetsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: _auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var pets = snapshot.data!.docs;
        if (pets.isEmpty) {
          return Center(
            child: Text(
              'No pets found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: pets.length + 1, // Add 1 for the buttons at the bottom
          itemBuilder: (context, index) {
            if (index == pets.length) {
              // Buttons at the bottom
              return Column(
                children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppointmentScreen()),
                      );
                    },
                    child: Text('View Appointments'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(300, 50),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BillingScreen()),
                      );
                    },
                    child: Text('Go to Billing'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(300, 50),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              );
            }
            var pet = pets[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PetProfileScreen(petId: pet.id)),
                );
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet Image
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300], // Placeholder for image
                        child: pet['imageUrl'] != null
                            ? Image.network(
                          pet['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.pets,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                            : Center(
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Name and Breed
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet['name'] ?? 'Unknown',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    pet['breed'] ?? 'Unknown Breed',
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.pink[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.female,
                                  color: Colors.pink,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // About Section
                          Text(
                            'About ${pet['name'] ?? 'Pet'}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailChip('Age', pet['age'] ?? 'N/A'),
                              _buildDetailChip('Weight', pet['weight'] ?? 'N/A'),
                              _buildDetailChip('Height', pet['height'] ?? 'N/A'),
                              _buildDetailChip('Color', pet['color'] ?? 'N/A'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            pet['description'] ?? 'No description available',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 16),
                          // Status Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${pet['name'] ?? 'Pet'}'s Status",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to a detailed status screen if needed
                                },
                                child: Text(
                                  'Contact Vet',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatusIndicator('Health', 'Abnormal', Colors.red),
                              _buildStatusIndicator('Food', 'Last Fed', Colors.green),
                              _buildStatusIndicator('Mood', 'Abnormal', Colors.red),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Implement check food functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Check Food'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Implement whistle functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Whistle'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String status, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              label == 'Health'
                  ? Icons.favorite
                  : label == 'Food'
                  ? Icons.fastfood
                  : Icons.mood,
              color: color,
              size: 30,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          status,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}