import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAppointmentScreen extends StatefulWidget {
  final QueryDocumentSnapshot appointment;

  EditAppointmentScreen({required this.appointment});

  @override
  _EditAppointmentScreenState createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late DateTime _selectedDate;
  late String _type;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment['date'].toDate();
    _type = widget.appointment['type'];
  }

  Future<void> _updateAppointment() async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointment.id)
        .update({
      'type': _type,
      'date': _selectedDate,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reschedule Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            TextFormField(
              initialValue: _type,
              onChanged: (value) => _type = value,
              decoration: InputDecoration(
                  labelText: 'Appointment Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

              ),
            ),
            ListTile(
              title: Text('Selected Date: ${_selectedDate.toString()}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                    color: CupertinoColors.black,
                    onPressed: _updateAppointment,
                    child: DefaultTextStyle(
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal,color: CupertinoColors.white),
                        child: Text('Save Changes')
                    )
                )
            ),
          ],
        ),
      ),
    );
  }
}