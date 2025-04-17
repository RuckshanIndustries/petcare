import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../app_config.dart';
import '../admin/admin_dashboard_screen.dart';
import '../pet_owner/dashboard_screen.dart';
import '../vet/vet_dashboard_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  String _role = 'Pet Owner';
  String _errorMessage = '';
  bool _isPasswordVisible = false;

  Future<void> _registerWithEmail() async {
    // Input validation
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (_role == 'Veterinarian' && _specialtyController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your specialty');
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_role == 'Veterinarian') {
        userData['specialty'] = _specialtyController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .doc(userCredential.user!.uid)
          .set(userData);

      // Clear the text fields
      _clearFields();

      // Navigate to the appropriate dashboard
      _navigateToScreenBasedOnRole(userCredential.user!.uid);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      _clearFields();
    }
  }

  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled the login

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user == null) {
        setState(() => _errorMessage = 'Google registration failed');
        return;
      }

      // Check if user exists in Firestore, if not, create a new user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? 'User',
          'role': _role, // Use selected role
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Google registration failed. Please try again.');
    }
  }

  Future<void> _registerWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        setState(() => _errorMessage = 'Facebook registration cancelled');
        return;
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user == null) {
        setState(() => _errorMessage = 'Facebook registration failed');
        return;
      }

      // Check if user exists in Firestore, if not, create a new user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(user.uid).set({
          'email': user.email ?? '',
          'name': user.displayName ?? 'User',
          'role': _role, // Use selected role
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Facebook registration failed. Please try again.');
    }
  }

  Future<void> _registerWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      User? user = userCredential.user;
      if (user == null) {
        setState(() => _errorMessage = 'Apple registration failed');
        return;
      }

      // Check if user exists in Firestore, if not, create a new user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(user.uid).set({
          'email': user.email ?? '',
          'name': user.displayName ?? 'User',
          'role': _role, // Use selected role
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Apple registration failed. Please try again.');
    }
  }

  Future<void> _navigateToScreenBasedOnRole(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
    await FirebaseFirestore.instance.collection(AppConfig.usersCollection).doc(uid).get();

    if (!userDoc.exists || userDoc.data() == null) {
      setState(() => _errorMessage = 'User data not found in Firestore');
      return;
    }

    String role = userDoc.data()?['role'] ?? '';
    Widget screen;
    switch (role) {
      case 'Pet Owner':
        screen = DashboardScreen();
        break;
      case 'Veterinarian':
        screen = VetDashboardScreen();
        break;
      case 'Admin':
        screen = AdminDashboardScreen();
        break;
      default:
        setState(() => _errorMessage = 'Unknown user role');
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _specialtyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back to Login link
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Name Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 16),
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 16),
                // Role Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Role',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RadioListTile<String>(
                      title: Text('Pet Owner', style: TextStyle(fontFamily: 'Poppins')),
                      value: 'Pet Owner',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value!),
                      activeColor: Colors.green,
                    ),
                    RadioListTile<String>(
                      title: Text('Veterinarian', style: TextStyle(fontFamily: 'Poppins')),
                      value: 'Veterinarian',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value!),
                      activeColor: Colors.green,
                    ),
                    RadioListTile<String>(
                      title: Text('Admin', style: TextStyle(fontFamily: 'Poppins')),
                      value: 'Admin',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value!),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                if (_role == 'Veterinarian') ...[
                  SizedBox(height: 16),
                  TextField(
                    controller: _specialtyController,
                    decoration: InputDecoration(
                      labelText: 'Veterinarian Specialty',
                      prefixIcon: Icon(Icons.medical_services, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _registerWithEmail,
                    child: Text('SIGN UP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
                    ),
                  ),
                SizedBox(height: 16),
                // Social Registration Divider
                Text(
                  'or sign up with',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),
                // Google Registration Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _registerWithGoogle,
                    icon: Image.asset(
                      'assets/google_icon.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Sign Up With Google',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Facebook Registration Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _registerWithFacebook,
                    icon: Image.asset(
                      'assets/facebook_icon.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Sign Up With Facebook',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Apple Registration Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _registerWithApple,
                    icon: Image.asset(
                      'assets/apple_icon.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Sign Up With Apple',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Copyright Notice
                Text(
                  '© All Rights Reserved Pet Health Care - 2025',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}