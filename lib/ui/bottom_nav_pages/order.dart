import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce/Rating.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class OrderPlacementPage extends StatefulWidget {
  @override
  _OrderPlacementPageState createState() => _OrderPlacementPageState();
}

class _OrderPlacementPageState extends State<OrderPlacementPage> {
  @override
  void initState() {
    super.initState();
    _handlePayment(
      0.0, // Total amount (example value, replace with actual total)
      FirebaseAuth.instance.currentUser!.email ?? '', // Current user's email
      FirebaseAuth.instance.currentUser!.displayName ?? '', // Current user's display name
      '', // User phone number (you may need to fetch this from Firestore)
      '',
      '',
    );
  }

  void _handlePayment(double total, String userEmail, String userName,
      String userPhoneNumber, String location,String status) async {
    CollectionReference ordersRef =
    FirebaseFirestore.instance.collection("orders");

    // Prepare data for Firestore
    Map<String, dynamic> orderData = {
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'userEmail': userEmail,
      'userName': userName,
      'userPhoneNumber': userPhoneNumber,
      "location": location,
      'totalAmount': total,
      'timestamp': Timestamp.now(),
      'products': [],
      'status': status,
    };

    // Retrieve cart items
    CollectionReference cartItemsRef =
    FirebaseFirestore.instance.collection("users-cart-items");
    QuerySnapshot cartSnapshot =
    await cartItemsRef.doc(userEmail).collection("items").get();

    List<Map<String, dynamic>> products = [];
    cartSnapshot.docs.forEach((doc) {
      Map<String, dynamic> productData =
      doc.data() as Map<String, dynamic>;
      products.add({
        'name': productData['name'],
        'price': productData['price'],
        'image': productData['image'],
      });
    });

    orderData['products'] = products;

    // Store data in Firestore
    await ordersRef.add(orderData);

    // Clear cart after the order is placed
    await cartItemsRef.doc(userEmail).collection("items").get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });

    // Navigate to the order page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OrderPage(userEmail: userEmail)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Placement'),
      ),
      body: Center(
        child: CircularProgressIndicator(), // Placeholder widget while processing
      ),
    );
  }
}
class OrderPage extends StatelessWidget {
  final String userEmail;
  final FlutterTts flutterTts = FlutterTts();

  OrderPage({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BottomNavController()),
            );
          },
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where('userEmail', isEqualTo: userEmail)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // Filter out orders with a total amount of 0.0
          final filteredOrders = snapshot.data!.docs.where((order) => (order['totalAmount'] as double) != 0.0).toList();

          if (filteredOrders.isEmpty) {
            return Center(
              child: Text('No orders found.'),
            );
          }

          _speakOrders(context, filteredOrders); // Speak orders

          return ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> orderData = filteredOrders[index].data() as Map<String, dynamic>;
              List<dynamic> products = orderData['products'] ?? [];
              Timestamp timestamp = orderData['timestamp'];

              // Filter products with price greater than 0
              List<Map<String, dynamic>> filteredProducts = products.where((product) => product['price'] > 0).toList().cast<Map<String, dynamic>>();

              return GestureDetector(
                onTap: () {
                  String orderId = filteredOrders[index].id; // Get the orderId
                  // Navigate to the rating page when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RatingPage(
                        orderUserName: orderData['userName'],
                        productList: filteredProducts,
                        orderId: orderId, // Pass the orderId here
                      ),
                    ),
                  );

                },
                child: Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order Details'),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteOrder(filteredOrders[index].reference);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text('Timestamp: ${_formatTimestamp(timestamp)}'),
                        Text('Total Amount: ${orderData['totalAmount']}'),
                        Text('Status: ${orderData['status']}'),
                        SizedBox(height: 10),
                        Text('Products:'),
                        DataTable(
                          columns: [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Image')),
                          ],
                          rows: filteredProducts.map((product) {
                            return DataRow(
                              cells: [

                                DataCell(Text(product['name'])),
                                DataCell(Text(product['price'].toString())),
                                DataCell(
                                  product['image'] != null
                                      ? Image.network(product['image'])
                                      : SizedBox(),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );



        },
      ),
    );
  }

  void _deleteOrder(DocumentReference reference) {
    reference.delete();
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }

  Future<void> _speakOrders(BuildContext context, List<DocumentSnapshot> orders) async {
    for (var order in orders) {
      Map<String, dynamic> orderData = order.data() as Map<String, dynamic>;
      Timestamp timestamp = orderData['timestamp'];

      DateTime currentTime = DateTime.now();
      DateTime orderTime = timestamp.toDate();
      Duration difference = currentTime.difference(orderTime);

      if (difference.inHours >= 0) {
        // Speak order details if it was placed before 7 hours
        await flutterTts.speak('Order placed ${difference.inHours} hours ago.');

        // Speak order details
        await flutterTts.speak('Order details for ${orderData['userName']}:');

        // Speak product details
        List<dynamic> products = orderData['products'] ?? [];
        for (var product in products) {
          await flutterTts.speak('Product: ${product['name']}, Price: ${product['price']},');
        }

        // Speak total amount and status
        await flutterTts.speak('Total Amount: ${orderData['totalAmount']}, Status: ${orderData['status']}.');

        // Ask user if they want to go to the rating page
        await flutterTts.speak("Would you like to go to the rating page?");

        // Listen for user response
        stt.SpeechToText speech = stt.SpeechToText();
        bool available = await speech.initialize();
        if (available) {
          speech.listen(
            onResult: (result) async {
              String userResponse = result.recognizedWords.toLowerCase();
              if (result.finalResult) {
                if (userResponse.contains("yes") || userResponse.contains("good") || userResponse.contains("ok")) {
                  // Navigate to the rating page
                  String orderId = order.id;
                  List<Map<String, dynamic>> filteredProducts = (orderData['products'] as List).where((product) => product['price'] > 0).toList().cast<Map<String, dynamic>>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RatingPage(
                        orderUserName: orderData['userName'],
                        productList: filteredProducts,
                        orderId: orderId,
                      ),
                    ),
                  );
                }
              }
            },
          );
        }
      }
    }
  }

}




