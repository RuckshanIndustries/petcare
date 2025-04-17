import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isNotificationsEnabled = false;
  bool isDarkModeEnabled = false;
  String? userName;
  String? userEmail;
  String? userRole;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No user logged in';
            _isLoading = false;
          });
        }
        return;
      }

      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User data not found in Firestore';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          userName = userDoc.data()!['name'] ?? 'Unknown';
          userEmail = userDoc.data()!['email'] ?? 'Unknown';
          userRole = userDoc.data()!['role'] ?? 'Unknown';
          isDarkModeEnabled = userDoc.data()!['darkMode'] ?? false;
          isNotificationsEnabled = userDoc.data()!['notificationsEnabled'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading user data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserSettings() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .update({
        'darkMode': isDarkModeEnabled,
        'notificationsEnabled': isNotificationsEnabled,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error saving settings: $e');
      }
    }
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Name: ${userName ?? 'Loading...'}',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Email: ${userEmail ?? 'Loading...'}',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Role: ${userRole ?? 'Loading...'}',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Preferences',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                trailing: Switch(
                  value: isDarkModeEnabled,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        isDarkModeEnabled = value;
                      });
                      _updateUserSettings();
                    }
                  },
                  activeColor: Colors.green,
                ),
              ),
              ListTile(
                title: Text(
                  'Notifications',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                trailing: Switch(
                  value: isNotificationsEnabled,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        isNotificationsEnabled = value;
                      });
                      _updateUserSettings();
                    }
                  },
                  activeColor: Colors.green,
                ),
              ),
              ListTile(
                title: Text(
                  'Logout',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.red),
                ),
                trailing: Icon(Icons.logout, color: Colors.red),
                onTap: _logout,
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
                  ),
                ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  '© All Rights Reserved Petsie Posse - 2022',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                    fontSize: 12,
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