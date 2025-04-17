import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../admin/admin_dashboard_screen.dart';
import '../pet_owner/dashboard_screen.dart';
import '../vet/vet_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _navigateToScreenBasedOnRole(user.uid);
      }
    });
  }

  Future<void> _navigateToScreenBasedOnRole(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

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

  Future<void> _loginWithEmail() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        setState(() => _errorMessage = 'User authentication failed');
        return;
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Invalid email or password. Please try again.');
    }
  }

  Future<void> _loginWithGoogle() async {
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
        setState(() => _errorMessage = 'Google login failed');
        return;
      }

      // Check if user exists in Firestore, if not, create a new user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? 'User',
          'role': 'Pet Owner', // Default role for social login
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Google login failed. Please try again.');
    }
  }

  Future<void> _loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        setState(() => _errorMessage = 'Facebook login cancelled');
        return;
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user == null) {
        setState(() => _errorMessage = 'Facebook login failed');
        return;
      }

      // Check if user exists in Firestore, if not, create a new user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'name': user.displayName ?? 'User',
          'role': 'Pet Owner', // Default role for social login
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Facebook login failed. Please try again.');
    }
  }

  Future<void> _loginWithApple() async {
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
        setState(() => _errorMessage = 'Apple login failed');
        return;
      }

      // Check if user exists in Firestore, if not, create a new user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'name': user.displayName ?? 'User',
          'role': 'Pet Owner', // Default role for social login
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _navigateToScreenBasedOnRole(user.uid);
    } catch (e) {
      setState(() => _errorMessage = 'Apple login failed. Please try again.');
    }
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
                // Create an account link
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
                    child: Text(
                      'Create an account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
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
                SizedBox(height: 8),
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loginWithEmail,
                    child: Text('LOGIN'),
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
                // Social Login Divider
                Text(
                  'or connect with',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),
                // Google Login Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: Image.asset(
                      'assets/google_icon.png', // Add Google icon to assets
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Login With Google',
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
                // Facebook Login Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loginWithFacebook,
                    icon: Image.asset(
                      'assets/facebook_icon.png', // Add Facebook icon to assets
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Login With Facebook',
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
                // Apple Login Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loginWithApple,
                    icon: Image.asset(
                      'assets/apple_icon.png', // Add Apple icon to assets
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Login With Apple',
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
                SizedBox(height: 16),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
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