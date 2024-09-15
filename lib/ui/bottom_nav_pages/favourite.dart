import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_ecommerce/ui/product_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Favorite extends StatefulWidget {
  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavController()));
          },
        ),
        title: Text('Favorites'),
      ),
      body: SafeArea(
        child: FavoriteItemList(),
      ),
    );
  }

  void _startListening() {
    speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          String spokenText = result.recognizedWords.toLowerCase().trim();
          if (spokenText == 'back') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavController()));
          }
        }
      },
    );
  }
}

class FavoriteItemList extends StatelessWidget {

  final FlutterTts flutterTts = FlutterTts();
  Future<void> _speakFavoritesList(QuerySnapshot snapshot) async {
    await flutterTts.speak('Here are your favorite items.');
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String name = data['name'];
      double price = data['price'] != null ? double.parse(data['price'].toString()) : 0.0;
      await flutterTts.speak('$name. Price: ${price.toStringAsFixed(2)} birr');
    }
  }
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;
    CollectionReference _favoriteItemsRef =
    FirebaseFirestore.instance.collection("users-favourite-items");

    Future<void> _speakEmptyFavorites() async {
      await flutterTts.speak('You have no favorite items.');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _favoriteItemsRef
          .doc(currentUser!.email)
          .collection("items")
          .snapshots(),
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
          _speakEmptyFavorites();
          return Center(
            child: Text('You have no favorite items.'),
          );
        }

        _speakFavoritesList(snapshot.data!); // Speak favorite items list when data is available

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            Map<String, dynamic> data =
            document.data() as Map<String, dynamic>;
            return FavoriteItem(
              product: data,
              onTapRemove: () {
                _removeFromFavorites(currentUser.email!, document.id);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _removeFromFavorites(
      String userEmail, String itemId) async {
    CollectionReference _favoriteRef =
    FirebaseFirestore.instance.collection("users-favourite-items");

    await _favoriteRef
        .doc(userEmail)
        .collection("items")
        .doc(itemId)
        .delete();
  }
}


class FavoriteItem extends StatelessWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onTapRemove;

  FavoriteItem({
    required this.product,
    required this.onTapRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (product == null ||
        product!.isEmpty ||
        !product!.containsKey('name') ||
        !product!.containsKey('price')) {
      return SizedBox(); // Return an empty widget if product is null or missing required keys
    }

    return GestureDetector(

      child: ListTile(
        onTap: () {
          // Ensure product data is not null and contains necessary information
          if (product != null && product!.containsKey('id')) {
            // Navigate to the product details screen using the product ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetails(product!['id']), // Assuming 'id' is the key for the product ID
              ),
            );
          } else {
            // Handle the case where product details are not available
            print("Error: Product details not available");
            // You can show an error message or handle it based on your application's requirements
          }
        },
        leading: product!.containsKey('image')
            ? Image.network(product!['image'])
            : SizedBox(), // Check if image key exists

        // Use null checks for title and subtitle
        title:
        product!.containsKey('name') ? Text(product!['name']) : Text('N/A'),
        subtitle: product!.containsKey('price')
            ? Text('Price: ${product!['price'].toStringAsFixed(2)} birr')
            : Text('Price: N/A'),

        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: onTapRemove,
        ),
      ),
    );
  }
}
