import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_pages/cart.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_pages/favourite.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_pages/order.dart';
import 'package:flutter_ecommerce/ui/category_screen.dart';
import 'package:flutter_ecommerce/ui/discount_banner.dart';
import 'package:flutter_ecommerce/ui/profile/profile_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../product_details_screen.dart';
import '../search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _products = [];
  var _firestoreInstance = FirebaseFirestore.instance;
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  bool isListening = false;
  String selectedVoice = 'default'; // Default voice
  bool isVoiceEnabled = true;
  get category => [];


  void _speakProductInformation(Map<String, dynamic> product) async {
    // Speak out the product details
    await flutterTts.speak(
      "Product Name: ${product["product-name"]}. Product Price: ${product["product-price"]} birr",
    );
    await flutterTts.speak("Is this the product you are looking for?");
    bool listening = true;
    int currentIndex=0;
    // Listen for voice commands
    while (listening) {
      await speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String spokenText = result.recognizedWords.toLowerCase();
            if (spokenText == 'next') {
              // Speak the next product if available
              if (currentIndex < _products.length - 1) {
                currentIndex++;
                await flutterTts.stop(); // Stop previous speech before speaking new product
                 _speakProductInformation(_products[currentIndex]);
              } else {
                await flutterTts.speak("There are no more products.");
              }
            } else if (spokenText == 'back') {
              // Speak the previous product if available
              if (currentIndex > 0) {
                currentIndex--;
                await flutterTts.stop(); // Stop previous speech before speaking new product
                 _speakProductInformation(_products[currentIndex]);
              } else {
                await flutterTts.speak("This is the first product.");
              }
            } else if (spokenText == 'yes') {
              // Navigate to product details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetails(product),
                ),
              );
              // Stop listening
              listening = false;
            } else {
              // Handle unrecognized commands
              await flutterTts.speak("Sorry, I didn't understand.");
             _startListening();
            }
          }
        },
      );
    }
  }
  fetchProducts() async {
    QuerySnapshot qn = await _firestoreInstance.collection("products").get();

    // Check if there are at least three products available
    if (qn.docs.length >= 3) {
      // Generate three random indices
      List<int> randomIndices = [];
      while (randomIndices.length < 3) {
        int randomIndex = Random().nextInt(qn.docs.length);
        if (!randomIndices.contains(randomIndex)) {
          randomIndices.add(randomIndex);
        }
      }

      // Populate _products list with randomly selected products
      setState(() {
        _products = randomIndices.map((index) => {
          "product-name": qn.docs[index]["product-name"],
          "product-description": qn.docs[index]["product-description"],
          "product-price": qn.docs[index]["product-price"],
          "product-img": qn.docs[index]["product-img"],
          "sizes": qn.docs[index]["sizes"],
          "colors": qn.docs[index]["colors"],
        }).toList();
      });
    } else {
      // If there are less than three products, populate _products list with all products
      setState(() {
        _products = qn.docs.map((doc) => {
          "product-name": doc["product-name"],
          "product-description": doc["product-description"],
          "product-price": doc["product-price"],
          "product-img": doc["product-img"],
          "sizes": doc["sizes"],
          "colors": doc["colors"],
        }).toList();
      });
    }
  }

  speak(String message) async {
    await flutterTts.speak(message);
  }

  @override
  void initState() {
    fetchProducts();
    super.initState();
    _speakWelcome();
  }
  @override
  void dispose() {
    // Stop speech recognition when the page is disposed
    stopListening();
    super.dispose();
  }

  void toggleVoice() {
    setState(() {
      isVoiceEnabled = !isVoiceEnabled; // Toggle the voice status
    });
    if (!isVoiceEnabled) {
      speech.stop(); // If voice is disabled, stop listening
    }
  }
  Future _speakWelcome() async {
    await speak(
        'Welcome to homepage. You can get our categories and special products.');
    await speak('you can goto the navbar say for cart say Cart for order say order');
    await speak(
        'for Category Say Category, for Special products Say Products');
    await Future.delayed(Duration(seconds: 1));
    _startListening();
  }
  Future<void> AskCategory() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('category').get();

      if (querySnapshot.docs.isNotEmpty) {
        List<String> categories = querySnapshot.docs.map((doc) => doc.id).toList();
        String categoryText = "We have ${categories.join(' and ')} categories.";
        await speak(categoryText);
        await Future.delayed(Duration(seconds: 1));
        listenForCategory();
      } else {
        await speak("No categories found.");
      }
    } catch (error) {
      print('Error fetching categories: $error');
      // Handle error if needed
    }
  }


  void listenForCategory() {
    speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          // Stop listening when final result is receive
          // Process the recognized speech result
          String category = result.recognizedWords.toLowerCase().trim();
          // Check for variations of "clothes"
          if (category.contains('clothe') ||
              category.contains('clothes') ||
              category.contains('clo') ||
              category.contains('close')) {
            // If the recognized category contains variations of "clothes", change it to "clothes"
            category = 'clothes';
          }
          else if(category.contains('shoes')|| category.contains('choose')||category.contains('shose')){
            category='shoes';
          }
          handleCategory(category);
        }
      },
    );
    setState(() {
      isListening = true;
    });
  }


  void handleCategory(String category) async {
    try {
      // Check if the selected category exists in Firestore
      DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('category')
          .doc(category)
          .get();

      if (categorySnapshot.exists) {
        // If category exists, navigate to ProductsPage
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage(category: category),));
        stopListening();
      } else {
        // If category doesn't exist, inform the user and ask again
        await speak("Sorry, $category category not found. Please try again.");
        AskCategory();
      }
    } catch (error) {
      print('Error handling category: $error');
      // Handle error if needed
    }
  }

  bool enableSpeech = true;

  void _startListening() {
    if (!enableSpeech) return;
    speech.listen(
      onResult: (result) {
        setState(() {
          print(result.recognizedWords);
          // Process the recognized speech result
          if (result.finalResult) {
            // If final result, process the spoken words
            handleVoiceCommand(result.recognizedWords);
          }
        });
      },
    );
    speech.errorListener = (error) {
      // Handle speech recognition errors
      if (error.permanent) {
        // Handle permanent errors
        print("Permanent error occurred: ${error.errorMsg}");
        // If error_no_match occurs, ask again for the category
        if (error.errorMsg == "error_no_match") {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavController(),));
        }
      } else {
        // Handle non-permanent errors
        print("Temporary error occurred: ${error.errorMsg}");
        // You might want to retry the operation or notify the user accordingly
      }
    };

    setState(() {
      isListening = true;
    });
  }


  stopListening() {
    if (!enableSpeech) {
      setState(() {
        isListening = false;
      });
      return;
    }
    speech.stop();
    setState(() {
      isListening = false;
    });
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        print("Product Document ID: ${product}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetails(product),

          ),

        );
      },
      child: Card(
        elevation: 3,
        child: Container(
          width: 120,
          padding: EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 90,
                child: Image.network(
                  product["product-img"][0],
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "${product["product-name"]}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                " ${product["product-price"].toString()} birr",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void handleVoiceCommand(String command) async {
    command = command.toLowerCase();
    stopListening();
    if (command.contains('category')) {
      await AskCategory();
    } else if (command.contains('product')) {
      bool productFound = false;
      // Read out each product information
      stopListening();
      await flutterTts.speak("Here are the special product lists :");
      stopListening();
      for (var product in _products) {
        _speakProductInformation(product);
        if (command.contains(product["product-name"].toLowerCase())) {
          // Product found, navigate to its detail page
          productFound = true;
          _navigateToProductDetails(product);
          break; // Exit the loop after navigating
        }
      }
      // If no product is found, provide feedback
      if (!productFound) {
        await flutterTts.speak("Sorry, I couldn't find information about that product.");
        _startListening();
      }
    } else if (command.contains('favorite') || command.contains('favored')|| command.contains('favoret')|| command.contains('fa')|| command.contains('Fa')) {
      // Navigate to the favorites page
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => Favorite()));
    } else if (command.contains('cart')||command.contains('card')||command.contains('C')||command.contains('Cart')||command.contains('Card')) {
      // Navigate to the cart page
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => Cart()));
    } else if (command.contains('order')||command.contains('Order')) {
      // Navigate to the payment page
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderPlacementPage()));
    } else if (command.contains('information')) {
      // Navigate to the personal information page
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen()));
    } else {
      // If command not recognized, provide feedback
      stopListening();
      await flutterTts.speak("Sorry, I didn't understand that. Please try again.");
      Duration(seconds: 3);
      _startListening();
    }
  }
  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetails(product),
      ),

    );
    stopListening();
  }

  void changeVoice(String newVoice) async {
    selectedVoice = newVoice;
    await flutterTts.setVoice(selectedVoice as Map<String, String>);
    await speak("Voice changed");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintText: "Search products here",
                  hintStyle: TextStyle(fontSize: 20),
                  prefixIcon: const Icon(Icons.search),
                ),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => SearchScreen()),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            DiscountBanner(),
            Categories(),
            Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.only(left: 20),
              child: Text(
                "Special Offer for You",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20.0),
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _products.map((product) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 130,
                        height: 175,
                        child: _buildProductCard(context, product),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                // Navigate to the desired page when the icon is clicked
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => BottomNavController()),
                );
              },
              icon: Icon(
                Icons.refresh,
                color: Colors.blue, // Change the color of the icon
                size: 30, // Change the size of the icon
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          toggleVoice();
        },
        child: Icon(isListening ? Icons.mic : Icons.mic_none),
      ),


    );
  }
}
class CategoryItem extends StatelessWidget {
  final String imageAsset;
  final String name;
  final VoidCallback onTap;

  CategoryItem({
    required this.imageAsset,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imageAsset, width: 50, height: 50),
            SizedBox(height: 8),
            Text(name, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
