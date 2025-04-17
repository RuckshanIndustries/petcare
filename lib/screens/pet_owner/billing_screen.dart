import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class BillingScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to simulate payment
  Future<void> _handlePayment(String billId, BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return PaymentDialog(billId: billId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('appointments')
            .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var appointments = snapshot.data!.docs;
          if (appointments.isEmpty) {
            return Center(child: Text('No appointments found.'));
          }

          List<String> appointmentIds = appointments.map((e) => e.id).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('billings')
                .where('appointmentId', whereIn: appointmentIds)
                .snapshots(),
            builder: (context, billingSnapshot) {
              if (!billingSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var bills = billingSnapshot.data!.docs;
              if (bills.isEmpty) {
                return Center(child: Text('No bills found.'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  var bill = bills[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        'Amount: \$${bill['amount']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        'Status: ${bill['billStatus']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: bill['billStatus'] == 'paid'
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : IconButton(
                        icon: Icon(Icons.payment, color: Colors.green),
                        onPressed: () => _handlePayment(bill.id, context),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final String billId;

  PaymentDialog({required this.billId});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _cvvController = TextEditingController();
  String _selectedCardType = 'Visa';
  String _selectedMonth = "01";
  String _selectedYear = "25";
  double? _billAmount;
  String? _transactionReference;

  final List<String> _cardTypes = ['Visa', 'MasterCard', 'American Express'];
  final List<String> _months = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _years = List.generate(10, (index) => (25 + index).toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    _fetchBillDetails();
    _generateTransactionReference();
  }

  Future<void> _fetchBillDetails() async {
    DocumentSnapshot billDoc = await FirebaseFirestore.instance
        .collection('billings')
        .doc(widget.billId)
        .get();

    if (billDoc.exists) {
      setState(() {
        _billAmount = (billDoc['amount'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  void _generateTransactionReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    _transactionReference = List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _processPayment(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        await Future.delayed(Duration(seconds: 2));

        await FirebaseFirestore.instance.collection('billings').doc(widget.billId).update({
          'billStatus': 'paid',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );

        await _sendNotificationToPetOwner();
        await _sendNotificationToVet();
        await _sendNotificationToAdmin();

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _sendNotificationToPetOwner() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String petOwnerUserId = user.uid;

        DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        await notificationRef.set({
          'userId': petOwnerUserId,
          'title': 'Payment Successful',
          'body': 'Your payment for the appointment has been successfully processed.',
          'type': 'payment_success',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to pet owner: $e');
    }
  }

  Future<void> _sendNotificationToVet() async {
    try {
      DocumentSnapshot billDoc = await FirebaseFirestore.instance
          .collection('billings')
          .doc(widget.billId)
          .get();

      if (billDoc.exists) {
        String appointmentId = billDoc['appointmentId'];

        DocumentSnapshot appointmentDoc = await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .get();

        if (appointmentDoc.exists) {
          String vetUserId = appointmentDoc['vetId'];

          DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
          await notificationRef.set({
            'userId': vetUserId,
            'title': 'Payment Received',
            'body': 'The pet owner has successfully paid for the appointment.',
            'type': 'payment_received',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error sending notification to vet: $e');
    }
  }

  Future<void> _sendNotificationToAdmin() async {
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        String adminUserId = adminSnapshot.docs.first.id;

        DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        await notificationRef.set({
          'userId': adminUserId,
          'title': 'Payment Received for Appointment',
          'body': 'A pet owner has successfully paid for an appointment.',
          'type': 'payment_received',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Transaction Details',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Details
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Amount',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$${_billAmount?.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Transaction Reference No',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _transactionReference ?? 'N/A',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Select Card Type
              Text(
                'Select card type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _cardTypes.map((type) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCardType = type;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedCardType == type ? Colors.green : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: _selectedCardType == type ? Colors.green : Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              // Card Number
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter card number';
                  }
                  if (value.replaceAll('-', '').length != 16) {
                    return 'Card number must be 16 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Name on Card
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name on the card',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter name on card';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // CVV
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVC Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter CVV';
                  }
                  if (value.length != 3) {
                    return 'CVV must be 3 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Expiry Date
              Text(
                'Expiring Date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showMonthPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: Text(
                          _selectedMonth,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('/', style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showYearPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: Text(
                          _selectedYear,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(context),
          child: Text('Pay Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _months.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_months[index]),
                      onTap: () {
                        setState(() {
                          _selectedMonth = _months[index];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _years.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_years[index]),
                      onTap: () {
                        setState(() {
                          _selectedYear = _years[index];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 16) {
      text = text.substring(0, 16);
    }

    StringBuffer formattedText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i != 0 && i % 4 == 0) {
        formattedText.write('-');
      }
      formattedText.write(text[i]);
    }

    return TextEditingValue(
      text: formattedText.toString(),
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}