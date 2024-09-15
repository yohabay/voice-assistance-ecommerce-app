import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_pages/order.dart';
import 'package:flutter_ecommerce/ui/product_details_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import '../../const/AppColors.dart';

class Cart extends StatefulWidget {
  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speakWelcomeAndCartItems();
  }

  Future<void> _speakWelcomeAndCartItems() async {
    await flutterTts.speak('Welcome to your cart.');
    await speakCartItems();
  }

  Future<void> speakCartItems() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;
    CollectionReference _cartItemsRef =
    FirebaseFirestore.instance.collection("users-cart-items");

    try {
      QuerySnapshot snapshot =
      await _cartItemsRef.doc(currentUser!.email).collection("items").get();
      if (snapshot.docs.isNotEmpty) {
        await flutterTts.speak('Here are the items in your cart.');
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          await flutterTts.speak(data['name']);
          await flutterTts.speak('Price: ${data['price']} birr');
        }
        await flutterTts.speak('Would you like to proceed to payment?');
        speech.listen(
          onResult: (command) async {
            if (command.finalResult) {
              String response = command.recognizedWords.toLowerCase();
              if (response.contains('yes')) {
                _handlePayment(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OrderPlacementPage(),));
              }
            }
          },
        );
      } else {
        await flutterTts.speak('Your cart is empty.');
      }
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  void _handlePayment(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final String userEmail = user!.email!;

    FirebaseFirestore.instance
        .collection("users-form-data")
        .doc(userEmail)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        final String userName = documentSnapshot.get('name');
        final String userPhoneNumber = documentSnapshot.get('phone');
        final String location = documentSnapshot.get("location");
        final String subCity = documentSnapshot.get("subCity");
        final String street = documentSnapshot.get("street");
        final String homeNumber = documentSnapshot.get("homeNumber");

        // Retrieve total price from the cart
        double total = 0;
        FirebaseFirestore.instance
            .collection("users-cart-items")
            .doc(userEmail)
            .collection("items")
            .get()
            .then((QuerySnapshot snapshot) {
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            total += data['price'];
          }

          // Handle payment with the retrieved information
          _processPayment(total, userEmail, userName, userPhoneNumber, location, subCity, street, homeNumber);

          // Show a SnackBar to indicate successful order
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Order placed successfully!",
              style: TextStyle(fontSize: 20.0),
            ),
          ));

          // Navigate to the Order Placement Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderPlacementPage()),
          );
        });
      } else {
        print('Document does not exist in the database');
      }
    }).catchError((error) {
      print('Error retrieving document: $error');
    });
  }

  void _processPayment(double total, String userEmail, String userName, String userPhoneNumber, String location, String subCity, String street, String homeNumber) async {
    CollectionReference ordersRef = FirebaseFirestore.instance.collection("orders");

    // Retrieve user's current location
    Position? currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Error getting user's location: $e");
    }

    // Prepare data for Firestore
    Map<String, dynamic> orderData = {
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'userEmail': userEmail,
      'userName': userName,
      'userPhoneNumber': userPhoneNumber,
      'location': location,
      'subCity': subCity,
      'street': street,
      'homeNumber': homeNumber,
      'totalAmount': total,
      'timestamp': Timestamp.now(),
      'products': [],
      'status': "pending",
    };

    // Retrieve cart items
    CollectionReference cartItemsRef = FirebaseFirestore.instance.collection("users-cart-items");
    QuerySnapshot cartSnapshot = await cartItemsRef.doc(userEmail).collection("items").get();

    List<Map<String, dynamic>> products = [];
    for (var doc in cartSnapshot.docs) {
      Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
      products.add({
        'name': productData['name'],
        'price': productData['price'],
        'image': productData['image'],
      });
    }

    orderData['products'] = products;

    // Store data in Firestore
    await ordersRef.add(orderData);

    // Clear cart after the order is placed
    await cartItemsRef.doc(userEmail).collection("items").get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BottomNavController(),));
          },
        ),
      ),
      body: SafeArea(
        child: CartItemList(),
      ),
    );
  }
}

class CartItemList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;
    CollectionReference _cartItemsRef =
    FirebaseFirestore.instance.collection("users-cart-items");

    return StreamBuilder<QuerySnapshot>(
      stream: _cartItemsRef.doc(currentUser!.email).collection("items").snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('Your cart is empty.'),
          );
        }

        // Calculate total price
        double total = 0;
        for (var doc in snapshot.data!.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          total += data['price'];
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetails(data),
                            ));
                      },
                      child: ListTile(
                        title: Text(data['name']),
                        subtitle: Text('Price: ${data['price']} birr'),
                        leading: Image.network(data['image'], width: 50, height: 50),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _removeFromCart(currentUser.email!, document.id);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Total: ${total.toStringAsFixed(2)} birr',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // Handle proceed to payment
                  _CartState cartState = context.findAncestorStateOfType<_CartState>()!;
                  cartState._handlePayment(context);
                },
                child: Text(
                  "Proceed to Payment",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deep_orange,
                  elevation: 3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFromCart(String userEmail, String itemId) async {
    CollectionReference _cartRef = FirebaseFirestore.instance.collection("users-cart-items");
    await _cartRef.doc(userEmail).collection("items").doc(itemId).delete();
  }
}
