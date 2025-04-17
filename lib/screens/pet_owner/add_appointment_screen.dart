import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'billing_screen.dart';

class AddAppointmentScreen extends StatefulWidget {
  @override
  _AddAppointmentScreenState createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController(); // New controller for description
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedVetName = 'OPD Doctor'; // Default to OPD Doctor
  String? _selectedPetName;
  String? _selectedPetId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predefined time slots
  final List<TimeOfDay> _timeSlots = [
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 15, minute: 30), // 3:30 PM
    TimeOfDay(hour: 16, minute: 30), // 4:30 PM
    TimeOfDay(hour: 17, minute: 30), // 5:30 PM
  ];

  // Calendar variables
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Future<void> _scheduleAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedVetName != null &&
        _selectedPetId != null) {
      try {
        final appointmentDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        String vetId = _selectedVetName == 'OPD Doctor' ? 'no_vet' : await _getVetIdByName(_selectedVetName!);

        await _firestore.collection('appointments').add({
          'type': _typeController.text.trim(),
          'description': _descriptionController.text.trim(), // Save the description
          'date': Timestamp.fromDate(appointmentDateTime),
          'vetId': vetId,
          'ownerId': _auth.currentUser?.uid ?? '',
          'petId': _selectedPetId,
          'status': 'scheduled',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment Scheduled Successfully')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BillingScreen()),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  Future<String> _getVetIdByName(String vetName) async {
    QuerySnapshot vetSnapshot = await _firestore
        .collection('users')
        .where('name', isEqualTo: vetName)
        .where('role', isEqualTo: 'Veterinarian')
        .get();

    if (vetSnapshot.docs.isNotEmpty) {
      return vetSnapshot.docs.first.id;
    } else {
      throw Exception('Vet not found');
    }
  }

  void _showVetPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'Veterinarian')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  var vetDocs = snapshot.data!.docs;
                  List<String> vetNames = ['OPD Doctor'];

                  vetNames.addAll(vetDocs.map((vet) => vet['name'] as String).toList());

                  return ListView.builder(
                    itemCount: vetNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(vetNames[index]),
                        onTap: () {
                          setState(() {
                            _selectedVetName = vetNames[index];
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showPetPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('pets')
                    .where('ownerId', isEqualTo: _auth.currentUser?.uid ?? '')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  var petDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: petDocs.length,
                    itemBuilder: (context, index) {
                      var pet = petDocs[index];
                      return ListTile(
                        title: Text(pet['name']),
                        onTap: () {
                          setState(() {
                            _selectedPetName = pet['name'];
                            _selectedPetId = pet.id;
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Appointment'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Appointment Type
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: 'Appointment Type (e.g., check-up, surgery)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the appointment type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Vet Picker
              OutlinedButton(
                onPressed: () => _showVetPicker(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _selectedVetName ?? 'Select Vet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SizedBox(height: 16),
              // Pet Picker
              OutlinedButton(
                onPressed: () => _showPetPicker(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _selectedPetName ?? 'Select Pet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SizedBox(height: 16),
              // Choose a Date Section
              Text(
                'Choose a Date',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDate, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(fontFamily: 'Poppins'),
                    weekendTextStyle: TextStyle(fontFamily: 'Poppins'),
                    selectedTextStyle: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.green),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontFamily: 'Poppins'),
                    weekendStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Pick a Time Section
              Text(
                'Pick a Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final time = _timeSlots[index];
                  final isSelected = _selectedTime != null &&
                      _selectedTime!.hour == time.hour &&
                      _selectedTime!.minute == time.minute;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          time.format(context),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              // Book Appointment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scheduleAppointment,
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: Text('Book Appointment'),
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
      ),
    );
  }
}