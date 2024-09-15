import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/const/AppColors.dart';
import 'package:flutter_ecommerce/ui/profile/components/profile_pic.dart';

class PaymentForm extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}
class _ProfileState extends State<PaymentForm> {
  TextEditingController? _nameController;
  TextEditingController? _phoneController;
  TextEditingController? _ageController;
  TextEditingController? _paymentMethodController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _paymentMethodController = TextEditingController();
    createPaymentCollection(); // Create the payment collection on initialization
  }

  @override
  void dispose() {
    _paymentMethodController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("users-form-data")
                .doc(FirebaseAuth.instance.currentUser!.email)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              var data = snapshot.data;
              if (data == null) {
                return Center(child: CircularProgressIndicator());
              }
              if (!_isEditing) {
                return showUserData(data);
              } else {
                return editUserData(data);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget showUserData(data) {
    return Column(
      children: [
        const ProfilePic(),
        Container(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${data['name']}',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 19,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      'Phone: ${data['phone']}',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      'Age: ${data['age']}',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      'Payment Method: ${data['paymentMethod'] ?? 'Not set'}',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Text('Edit',
                      style: TextStyle(color: Colors.white, fontSize: 18.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep_orange,
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget editUserData(data) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController =
              TextEditingController(text: data['name']),
          decoration: InputDecoration(labelText: 'Name'),
        ),
        TextFormField(
          controller: _phoneController =
              TextEditingController(text: data['phone']),
          decoration: InputDecoration(labelText: 'Phone'),
        ),
        TextFormField(
          controller: _ageController = TextEditingController(text: data['age']),
          decoration: InputDecoration(labelText: 'Age'),
        ),
        TextFormField(
          controller: _paymentMethodController,
          decoration: InputDecoration(labelText: 'Payment Method'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isEditing = false;
              updateUserData();
              updatePaymentMethod(_paymentMethodController!.text);
            });
          },
          child: Text('Update'),
        ),
      ],
    );
  }

  void updateUserData() {
    CollectionReference _collectionRef =
    FirebaseFirestore.instance.collection("users-form-data");
    _collectionRef.doc(FirebaseAuth.instance.currentUser!.email).update({
      "name": _nameController!.text,
      "phone": _phoneController!.text,
      "age": _ageController!.text,
    }).then((value) => print("Updated User Data Successfully"));
  }

  // Function to create the payment collection and document
  void createPaymentCollection() async {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    CollectionReference paymentCollection =
    FirebaseFirestore.instance.collection('users-payment-data');

    try {
      DocumentSnapshot documentSnapshot =
      await paymentCollection.doc(userEmail).get();
      if (!documentSnapshot.exists) {
        await paymentCollection.doc(userEmail).set({
          'paymentMethod': '', // Initialize payment method as an empty string
        });
        print('Payment collection created successfully!');
      } else {
        print('Payment collection already exists!');
      }
    } catch (error) {
      print('Error creating payment collection: $error');
    }
  }

  // Function to update payment information
  void updatePaymentMethod(String paymentMethod) async {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    CollectionReference paymentCollection =
    FirebaseFirestore.instance.collection('users-payment-data');

    try {
      var docSnapshot = await paymentCollection.doc(userEmail).get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>?; // Ensure data is typed correctly
        if (data != null && data.containsKey('paymentMethod')) {
          // User has a payment method
          // Display the payment method details
          print('Payment method: ${data['paymentMethod']}');
        } else {
          // User doesn't have a payment method
          // Display a message and an option to add payment method
          print('No payment method found');
          // Show UI to add payment method here
        }
      } else {
        print('Document does not exist for the user.');
      }
    } catch (error) {
      print('Error getting payment method: $error');
    }
  }
}
