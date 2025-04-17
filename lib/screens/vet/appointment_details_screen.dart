import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'medical_record_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppointmentDetailsScreen({required this.appointmentId});

  String _formatTime(Timestamp timestamp) {
    var date = timestamp.toDate();
    return DateFormat('h:mm a').format(date); // e.g., "2:51 pm"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('appointments').doc(appointmentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading appointment details.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No appointment details found.'));
          }

          var appointmentData = snapshot.data!.data() as Map<String, dynamic>;

          // Handle missing fields gracefully
          String type = appointmentData['type'] ?? 'No Type';
          String petId = appointmentData['petId'] ?? 'No Pet ID';
          String description = appointmentData['description'] ?? 'No description provided';
          String date = appointmentData['date'] != null
              ? _formatTime(appointmentData['date'] as Timestamp)
              : 'No Date';

          // Fetch pet and owner details based on petId
          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('pets').doc(petId).get(),
            builder: (context, petSnapshot) {
              if (petSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (petSnapshot.hasError) {
                return Center(child: Text('Error loading pet details.'));
              }

              if (!petSnapshot.hasData || !petSnapshot.data!.exists) {
                return Center(child: Text('No pet details found.'));
              }

              var petData = petSnapshot.data!.data() as Map<String, dynamic>;

              // Handle missing pet fields gracefully
              String petName = petData['name'] ?? 'No Pet Name';
              String ownerId = petData['ownerId'] ?? 'No Owner ID';
              String? petImageUrl = petData['imageUrl'];

              // Fetch user details (owner) based on ownerId
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(ownerId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError) {
                    return Center(child: Text('Error loading owner details.'));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Center(child: Text('No owner details found.'));
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                  // Ensure that the user has the role of 'pet owner'
                  String role = userData['role'] ?? 'No Role';
                  if (role != 'Pet Owner') {
                    return Center(child: Text('This user is not a pet owner.'));
                  }

                  // Get owner name
                  String ownerName = userData['name'] ?? 'No Owner Name';

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Card
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pet Image
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: petImageUrl != null
                                        ? Image.network(
                                      petImageUrl,
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
                                      // Pet Name
                                      Text(
                                        petName,
                                        style: Theme.of(context).textTheme.headlineMedium,
                                      ),
                                      SizedBox(height: 8),
                                      // Appointment Type and Date
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              type,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              date,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      // Description
                                      Text(
                                        'Description',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        description,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      SizedBox(height: 16),
                                      // Recommended For
                                      Text(
                                        'Recommended For',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        petName,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          // View Medical Record Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (petId != 'No Pet ID') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MedicalRecordScreen(
                                        petId: petId,
                                      ),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('No Pet ID'),
                                      content: Text('No Pet ID available'),
                                      actions: [
                                        TextButton(
                                          child: Text('OK'),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.camera_alt, color: Colors.white),
                              label: Text('View Medical Record'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
        },
      ),
    );
  }
}