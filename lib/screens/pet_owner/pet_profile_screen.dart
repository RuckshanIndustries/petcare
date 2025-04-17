import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetProfileScreen extends StatefulWidget {
  final String? petId;

  const PetProfileScreen({this.petId});

  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _colourController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      _loadPetData();
    }
  }

  Future<void> _loadPetData() async {
    var petDoc = await _firestore.collection('pets').doc(widget.petId).get();
    if (petDoc.exists) {
      setState(() {
        _nameController.text = petDoc['name'] ?? '';
        _breedController.text = petDoc['breed'] ?? '';
        _genderController.text = petDoc['gender'] ?? '';
        _ageController.text = petDoc['age']?.toString() ?? '';
        _colourController.text = petDoc['color'] ?? '';
        _heightController.text = petDoc['height']?.toString() ?? '';
        _weightController.text = petDoc['weight']?.toString() ?? '';
        _medicalHistoryController.text = petDoc['medicalHistory'] ?? '';
      });
    }
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      var petData = {
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'gender': _genderController.text.trim(),
        'age': _ageController.text.trim(),
        'color': _colourController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'ownerId': _auth.currentUser!.uid,
      };

      if (widget.petId == null) {
        await _firestore.collection('pets').add(petData);
      } else {
        await _firestore.collection('pets').doc(widget.petId).update(petData);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petId == null ? 'Add Pets' : 'Edit Pet'),
        actions: [
          TextButton(
            onPressed: () {
              // Placeholder for "Scan for Pets" functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Scan for Pets functionality not implemented')),
              );
            },
            child: Text(
              'Scan for Pets',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Added Pets Section
            Text(
              'Added Pets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
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
                  return Text(
                    'No pets added yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: pets.map((pet) {
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: pet['imageUrl'] != null
                                ? Image.network(
                              pet['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.pets,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                );
                              },
                            )
                                : Center(
                              child: Icon(
                                Icons.pets,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          pet['name'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.grey),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PetProfileScreen(petId: pet.id),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),
            // Manually Add Pet Section
            Text(
              'Manually Add Pet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Pet Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter the pet\'s name' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _breedController,
                    decoration: InputDecoration(
                      labelText: 'Breed Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter the pet\'s breed' : null,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _genderController,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Please enter the pet\'s gender' : null,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) =>
                          value!.isEmpty ? 'Please enter the pet\'s age' : null,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _colourController,
                          decoration: InputDecoration(
                            labelText: 'Colour',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Please enter the pet\'s colour' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            labelText: 'Height',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) =>
                          value!.isEmpty ? 'Please enter the pet\'s height' : null,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            labelText: 'Weight',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) =>
                          value!.isEmpty ? 'Please enter the pet\'s weight' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _medicalHistoryController,
                    decoration: InputDecoration(
                      labelText: 'Medical History',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter the pet\'s medical history' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _savePet,
                    child: Text(widget.petId == null ? 'Add Pet' : 'Update Pet'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}