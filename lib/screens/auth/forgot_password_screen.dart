import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Password reset failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
         children: [

           TextField(
             controller: _emailController,
             obscureText: true,
             decoration: InputDecoration(
               labelText: 'Enter password',
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

             ),
           ),
            SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
              color: CupertinoColors.black,
              onPressed: _resetPassword,
              child: DefaultTextStyle(
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal,color: CupertinoColors.white),
                  child: Text('Reset Password')
              )
          ),
          ),
    ]
        ),
      ),
    );
  }
}