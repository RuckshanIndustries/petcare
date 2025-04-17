import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_appointment_screen.dart';
import 'edit_appointment_screen.dart';

class AppointmentScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _navigateToEditScreen(BuildContext context, QueryDocumentSnapshot appointment) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EditAppointmentScreen(appointment: appointment),
      ),
    );
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.add_circled_solid,
            color: CupertinoColors.black,
          ),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => AddAppointmentScreen()),
            );
          },
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('appointments')
            .where('ownerId', isEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CupertinoActivityIndicator());
          }
          var appointments = snapshot.data!.docs;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appointment = appointments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.black),
                      child: Text(
                        '${'Details'} - ${appointment['type']}',
                      ),
                    ),

                    if (appointment['date'] != null)
                      DefaultTextStyle(
                        style: TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
                        child: Text(
                          'Checkup - ${appointment['date'].toDate().toString().split(' ')[0]}',
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      // Align buttons to the right
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.pencil, color: CupertinoColors.activeBlue),
                          onPressed: () {
                            _navigateToEditScreen(context, appointment);
                          },
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                          onPressed: () {
                            // Show confirmation dialog for deleting
                            showCupertinoDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CupertinoAlertDialog(
                                  title: Text('Delete Appointment'),
                                  content: Text('Are you sure you want to delete this appointment?'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog without deleting
                                      },
                                    ),
                                    CupertinoDialogAction(
                                      child: Text('Delete'),
                                      onPressed: () {
                                        _deleteAppointment(appointment.id); // Proceed with deleting
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(thickness: 1, color: CupertinoColors.systemGrey5),
                    // Row with Update and Delete buttons next to each appointment

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
