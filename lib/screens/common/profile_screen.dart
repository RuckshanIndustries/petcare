import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petcare/screens/pet_owner/pet_profile_screen.dart';
import 'package:petcare/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _phoneNumber = 'Not provided';
  String _role = "Pet Owner";
  String? _profileImageUrl;
  File? _profileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      var userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'] ?? 'Unknown User';
          _email = userDoc['email'] ?? 'No email provided';
          _phoneNumber = userDoc['phoneNumber'] ?? 'Not provided';
          _role = userDoc['role'] ?? 'Pet Owner';
          _profileImageUrl = userDoc['profileImageUrl'];
          if (!['Pet Owner', 'Veterinarian', 'Admin'].contains(_role)) {
            _role = 'Null';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _name = 'User Not Found';
          _email = _auth.currentUser!.email ?? 'No email';
          _phoneNumber = 'Not provided';
          _role = 'Pet Owner';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found in Firestore')),
        );
      }
    } catch (e) {
      setState(() {
        _name = 'Error';
        _email = _auth.currentUser!.email ?? 'Error';
        _phoneNumber = 'Error';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _uploadImage(_profileImage!);
        await _loadUserData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      String fileName = '${_auth.currentUser!.uid}_profile.jpg';
      String folder = _role.toLowerCase().replaceAll(' ', '_');
      Reference storageRef = FirebaseStorage.instance.ref().child('$folder/$fileName');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {

      await _auth.signOut();
      MaterialPageRoute(builder: (context) => LoginScreen());// Replace with your login route
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : _name),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFFF9800),
              child: Icon(
                Icons.pets,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Background Image
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            color: Colors.grey[300],
            child: Stack(
              children: [
                _profileImage != null
                    ? Image.file(
                  _profileImage!,
                  fit: BoxFit.cover,
                )
                    : _profileImageUrl != null
                    ? Image.network(
                  _profileImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 50,
                      ),
                    );
                  },
                )
                    : Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 50,
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 30),
                    onPressed: _pickProfileImage,
                  ),
                ),
              ],
            ),
          ),
          // User Details Card and Options List
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            TextButton.icon(
                              onPressed: _signOut,
                              icon: Icon(Icons.logout, color: Colors.red),
                              label: Text(
                                'Sign out',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              _email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              _phoneNumber,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Options List
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text(
                    'About me',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to About Me screen')),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: Icon(Icons.inventory),
                  title: Text(
                    'My Orders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to My Orders screen')),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text(
                    'My Address',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to My Address screen')),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: Icon(Icons.pets),
                  title: Text(
                    'Add Pet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PetProfileScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: Icon(Icons.devices),
                  title: Text(
                    'Add Device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to Add Device screen')),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}