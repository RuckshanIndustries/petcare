import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'billing_screen_admin.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getVetName(String vetId) async {
    try {
      DocumentSnapshot vetDoc = await _firestore.collection('users').doc(vetId).get();
      if (vetDoc.exists) {
        return vetDoc['name'] ?? 'Unknown Vet';
      } else {
        return 'Vet not found';
      }
    } catch (e) {
      return 'Error fetching vet name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('appointments').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CupertinoActivityIndicator());
          }

          var appointments = snapshot.data!.docs;
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      var appointment = appointments[index];

                      Timestamp timestamp = appointment['date'];
                      DateTime date = timestamp.toDate();
                      String formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";

                      return FutureBuilder<String>(
                        future: _getVetName(appointment['vetId']),
                        builder: (context, vetSnapshot) {
                          if (vetSnapshot.connectionState == ConnectionState.waiting) {
                            return CupertinoListTile(
                              title: Text('Loading vet name...'),
                              subtitle: Text('Date: $formattedDate'),
                              trailing: CupertinoActivityIndicator(),
                            );
                          }

                          if (vetSnapshot.hasError) {
                            return CupertinoListTile(
                              title: Text('Error loading vet name'),
                              subtitle: Text('Date: $formattedDate'),
                            );
                          }

                          String vetName = vetSnapshot.data ?? 'Unknown Vet';
                          Color statusColor = appointment['status'] == 'Confirmed'
                              ? CupertinoColors.black
                              : appointment['status'] == 'Pending'
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemRed;

                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DefaultTextStyle(
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 14,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$vetName - $formattedDate - ${appointment['status']}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Icon(CupertinoIcons.right_chevron),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => BillingScreen(
                                          appointmentId: appointment.id,
                                          vetId: appointment['vetId'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
