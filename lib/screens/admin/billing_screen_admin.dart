import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillingScreen extends StatefulWidget {
  final String appointmentId;
  final String vetId;

  BillingScreen({required this.appointmentId, required this.vetId});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _billStatus;
  double? _amount;
  double? _price;

  @override
  void initState() {
    super.initState();
    _fetchBillingDetails();
  }

  Future<void> _fetchBillingDetails() async {
    try {
      QuerySnapshot query = await _firestore
          .collection('billings')
          .where('appointmentId', isEqualTo: widget.appointmentId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        setState(() {
          _billStatus = doc['billStatus'];
          _amount = doc['amount'];
          _price = doc['price'];
        });
      } else {
        setState(() {
          _billStatus = "unpaid";
        });
      }
    } catch (e) {
      print('Error fetching billing details: $e');
    }
  }

  Future<void> _saveBillingDetails() async {
    try {
      double amount = double.parse(_amountController.text);
      double price = double.parse(_priceController.text);

      DocumentReference docRef = _firestore.collection('billings').doc();
      await docRef.set({
        'billingId': docRef.id,
        'appointmentId': widget.appointmentId,
        'vetId': widget.vetId,
        'amount': amount,
        'price': price,
        'billStatus': "unpaid",
        'timestamp': FieldValue.serverTimestamp(),
      });

      _fetchBillingDetails();
    } catch (e) {
      print('Error saving billing details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Billing Details'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.person_2),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _billStatus == null
              ? Center(child: CupertinoActivityIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: CupertinoColors.black),
                child: Text("Bill Status: $_billStatus")),

              SizedBox(height: 10),
              DefaultTextStyle(
                style: TextStyle(fontSize: 16,color:CupertinoColors.black),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Amount Paid: \$_amount"),
                    Text("Price: \$_price"),
                  ],
                ),
              ),

              SizedBox(height: 20),
              if (_billStatus != "paid") ...[
                CupertinoTextField(
                  controller: _amountController,
                  placeholder: 'Amount',
                  keyboardType: TextInputType.number,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: _priceController,
                  placeholder: 'Price',
                  keyboardType: TextInputType.number,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.black,
                    onPressed: _saveBillingDetails,
                    child: DefaultTextStyle(
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal,color: CupertinoColors.white),
    child: Text('Save Billing Details'),
    )


                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
