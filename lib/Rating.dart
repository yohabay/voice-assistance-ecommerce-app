import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RatingPage extends StatefulWidget {
  final String orderUserName;
  final List<Map<String, dynamic>> productList;
  final String orderId;

  RatingPage({required this.orderUserName, required this.productList, required this.orderId});

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  TextEditingController ratingController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  int currentProductIndex = 0; // Index of the current product being rated
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognition();
    _promptDeliveryConfirmation();
  }

  void _initializeSpeechRecognition() async {
    bool available = await speech.initialize();
    if (!available) {
      print('Speech recognition not available');
    }
  }

  void _speakProductInformation() async {
    await _speak('Please rate ${widget.productList[currentProductIndex]['name']}.');
    _startListeningRating();
  }

  Future<void> _speak(String text) async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  void _startListeningRating() async {
    if (isListening) return;
    bool available = await speech.listen(
      onResult: (result) {
        setState(() {
          String recognizedWords = result.recognizedWords.trim().toLowerCase();
          if (_isValidRating(recognizedWords)) {
            ratingController.text = recognizedWords;
            _submitRating(context); // Automatically submit the rating after it's filled
          } else if (recognizedWords.contains('delivered')) {
            // If the spoken words contain "delivered", mark the order as delivered
            _markOrderAsDelivered(context);
            _speak("The product is delivered");
          }
        });
      },
      onSoundLevelChange: (level) {
        // Can be used to visualize or monitor sound levels
      },
      listenFor: Duration(seconds: 10), // Listen for 10 seconds
      localeId: "en_US",
      cancelOnError: true,
      partialResults: false,
    );
    if (!available) {
      print('Listening failed to start');
    } else {
      setState(() {
        isListening = true;
      });
    }
  }

  void _stopListeningRating() async {
    await speech.stop();
    setState(() {
      isListening = false; // Set listening state to false when listening stops
    });
  }

  bool _isValidRating(String input) {
    int? rating = int.tryParse(input);
    return rating != null && rating >= 0 && rating <= 5; // Rating should be between 0 and 5
  }

  void _submitRating(BuildContext context) {
    int rating = int.tryParse(ratingController.text) ?? 0; // Parse the rating from the controller
    if (rating < 0 || rating > 5) {
      // Check if the rating is valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a rating between 0 and 5.'),
        ),
      );
      return;
    }

    // Construct rating data
    Map<String, dynamic> ratingData = {
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'rating': rating,
      // Add more fields as needed, such as timestamp, user name, etc.
    };

    // Update the orders collection
    FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'rating': ratingData,
    }).then((_) {
      // Rating submitted successfully for the order
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating submitted successfully for the order.'),
        ),
      );
      // Move to the next product to rate
      _moveToNextProduct();
    }).catchError((error) {
      // Error handling
      print('Failed to submit rating for the order: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating for the order. Please try again later.'),
        ),
      );
    });
  }

  void _moveToNextProduct() {
    // Check if there are more products to rate
    if (currentProductIndex < widget.productList.length - 1) {
      currentProductIndex++;
      // Speak the information for the next product
      _speakProductInformation();
    } else {
      // All products have been rated, prompt the user to confirm delivery
      _promptDeliveryConfirmation();
    }
  }

  void _promptDeliveryConfirmation() async {
    await _speak('Have you received all the products?');

    // Start listening for the user's response
    bool available = await speech.listen(
      onResult: (result) {
        String response = result.recognizedWords.toLowerCase();
        if (response.contains('yes')) {
          _markOrderAsDelivered(context);
          _stopListeningRating();
        }
      },
      listenFor: Duration(seconds: 10), // Listen for 10 seconds
      localeId: "en_US",
      cancelOnError: true,
      partialResults: false,
    );

    if (!available) {
      print('Listening failed to start');
    } else {
      setState(() {
        isListening = true;
      });
    }
  }

  void _markOrderAsDelivered(BuildContext context) {
    FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'status': 'delivered',
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order marked as delivered'),
      ));
      // Go back to the previous screen or navigate to the bottom navbar
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to mark order as delivered'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Order'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rate your experience with ${widget.orderUserName}:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            // Display product list
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.productList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> product = widget.productList[index];
                return ListTile(
                  leading: product['image'] != null ? Image.network(product['image']) : Icon(Icons.image),
                  title: Text(product['name']),
                  subtitle: Text('Price: ${product['price']}'),
                );
              },
            ),
            SizedBox(height: 20),
            // Rating input field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: ratingController,
                decoration: InputDecoration(
                  labelText: 'Enter Rating',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Submit Rating button
            ElevatedButton(
              onPressed: () {
                _submitRating(context);
              },
              child: Text('Submit Rating'),
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _markOrderAsDelivered(context); // Call method to mark order as delivered
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.green), // Change button color to green
                  ),
                  child: Text('Delivered'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
