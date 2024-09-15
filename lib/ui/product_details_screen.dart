import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce/const/AppColors.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_pages/cart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetails(this.product);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  bool isListening = false;

  int _selectedAmount = 1;
  String _selectedColor = "";
  String _selectedSize = "";
  bool _isFavorite = false;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    checkIfFavorite();
    _speakWelcome();
  }

  Future _speakWelcome() async {
    await flutterTts.speak('Welcome to Product Details.');
    speakProductDetails();
  }

  bool enableSpeech = true;

  void _startListening() {
    if (!enableSpeech) return;
    if (!enableSpeech) return;
    speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          // Process the recognized speech result
          handleVoiceCommand(result.recognizedWords.toLowerCase().trim());
        }
      },
    );
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

  void handleVoiceCommand(String command) async {
    // Implement logic to handle voice commands
    if (command.contains('favorite')) {
      _toggleFavorite();
      await flutterTts.speak("This Product add to favorites");
    } else if (command.contains('color')) {
      _selectColor(command);
    } else if (command.contains('size')) {
      _selectSize(command);
    } else if (command.contains('increase amount')) {
      _incrementAmount();
    } else if (command.contains('decrease amount')) {
      _decrementAmount();
    } else if (command.contains("total price")) {
      _speakTotalPrice();
    } else if (command.contains("yes") || command.contains("add")||command.contains('added')) {
      await flutterTts.speak('Ok go to the home page');
      addToCart();
      Navigator.push(context, MaterialPageRoute(builder: (context) => BottomNavController(),));
      stopListening();
    }  else {
      // Handle unrecognized commands
      await flutterTts
          .speak("Sorry, I didn't understand that. Please try again.");
      startListening();
    }

  }

  void _selectColor(String command) {
    // Implement logic to select color using voice command
    // Extract color name from the command and set _selectedColor accordingly
    String color = command.replaceAll('select color', '').trim();
    setState(() {
      _selectedColor = color;
    });
  }

  void _selectSize(String command) {
    // Implement logic to select size using voice command
    // Extract size from the command and set _selectedSize accordingly
    String size = command.replaceAll('select size', '').trim();
    setState(() {
      _selectedSize = size;
    });
  }

  void _speakTotalPrice() async {
    // Speak out the total price of the selected product
    double totalPrice = getTotalPrice();
    await flutterTts
        .speak("The total price is ${totalPrice.toStringAsFixed(2)} birr");
  }

  void startListening() {
    if (!enableSpeech) return;
    speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          // Process the recognized speech result
          handleVoiceCommand(result.recognizedWords.toLowerCase().trim());
        }
      },
    );
    setState(() {
      isListening = true;
    });
  }

  void speakProductDetails() async {
    // Speak out product name
    await flutterTts.speak("Product Name: ${widget.product["product-name"]}");
    await flutterTts.speak("Product Description: ${widget.product["product-description"]}");
    await flutterTts.speak("Product Price: ${widget.product["product-price"]} birr");
    await flutterTts.speak("Would you like to increase the amount?");

    // Listen for user voice commands
    speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          String text = result.recognizedWords.toLowerCase();
          if (text.contains("increase")) {
            // Perform logic to increase the amount
            _incrementAmount();
            // Speak the updated total price
            await flutterTts.speak("Total price is now ${getTotalPrice().toStringAsFixed(2)}  birr");

          }
          else if(text.contains('no')||text.contains('next')){
            await flutterTts.speak("Next, let's choose a color.");
          }
          await flutterTts.speak("Available colors are: ${widget.product["colors"]}");
          // Listen for user voice command to select color
          speech.listen(
            onResult: (colorResult) async {
              if (colorResult.finalResult) {
                String colorText = colorResult.recognizedWords.toLowerCase();
                if (widget.product["colors"].contains(colorText)) {
                  // Color selected by the user
                  _selectColor(colorText);
                  await flutterTts.speak("You've selected $colorText color.");

                  await flutterTts.speak("Next, let's choose a size.");
                  await flutterTts.speak("Available sizes are: ${widget.product["sizes"]}");

                  // Listen for user voice command to select size
                  speech.listen(
                    onResult: (sizeResult) async {
                      if (sizeResult.finalResult) {
                        String sizeText = sizeResult.recognizedWords.toLowerCase();
                        if (widget.product["sizes"].contains(sizeText)) {
                          // Size selected by the user
                          _selectSize(sizeText);
                          await flutterTts.speak("You've selected $sizeText size.");

                          // Speak the selected product details
                          speakSelectedProductDetails();
                        } else {
                          await flutterTts.speak("Sorry, $sizeText is not a valid size. Please try again.");
                          speech.listen(
                            onResult: (sizeResult) async {
                              if (sizeResult.finalResult) {
                                String sizeText = sizeResult.recognizedWords.toLowerCase();
                                if (widget.product["sizes"].contains(sizeText)) {
                                  // Size selected by the user
                                  _selectSize(sizeText);
                                  await flutterTts.speak("You've selected $sizeText size.");

                                  // Speak the selected product details
                                  speakSelectedProductDetails();
                                }
                              }
                            },
                          );
                        }
                      }
                    },
                  );
                } else {
                  await flutterTts.speak("Sorry, $colorText is not a valid color. Please try again.");
                  speech.listen(
                    onResult: (colorResult) async {
                      if (colorResult.finalResult) {
                        String colorText = colorResult.recognizedWords.toLowerCase();
                        if (widget.product["colors"].contains(colorText)) {
                          // Color selected by the user
                          _selectColor(colorText);
                          await flutterTts.speak("You've selected $colorText color.");

                          await flutterTts.speak("Next, let's choose a size.");
                          await flutterTts.speak("Available sizes are: ${widget.product["sizes"]}");

                          // Listen for user voice command to select size
                          speech.listen(
                            onResult: (sizeResult) async {
                              if (sizeResult.finalResult) {
                                String sizeText = sizeResult.recognizedWords.toLowerCase();
                                if (widget.product["sizes"].contains(sizeText)) {
                                  // Size selected by the user
                                  _selectSize(sizeText);
                                  await flutterTts.speak("You've selected $sizeText size.");

                                  // Speak the selected product details
                                  speakSelectedProductDetails();
                                } else {
                                  await flutterTts.speak("Sorry, $sizeText is not a valid size. Please try again.");
                                  speech.listen(
                                    onResult: (sizeResult) async {
                                      if (sizeResult.finalResult) {
                                        String sizeText = sizeResult.recognizedWords.toLowerCase();
                                        if (widget.product["sizes"].contains(sizeText)) {
                                          // Size selected by the user
                                          _selectSize(sizeText);
                                          await flutterTts.speak("You've selected $sizeText size.");

                                          // Speak the selected product details
                                          speakSelectedProductDetails();
                                        }
                                      }
                                    },
                                  );
                                }
                              }
                            },
                          );
                        }
                      }
                      speech.errorListener = (error) {
                        // Handle speech recognition errors
                        if (error.permanent) {
                          // Handle permanent errors
                          print("Permanent error occurred: ${error.errorMsg}");
                          // If error_no_match occurs, ask again for the category
                          if (error.errorMsg == "error_no_match") {
                            Navigator.pop(context);
                            speakProductDetails();
                          }
                        } else {
                          // Handle non-permanent errors
                          print("Temporary error occurred: ${error.errorMsg}");
                          // You might want to retry the operation or notify the user accordingly
                        }
                      };
                    },
                  );
                }
              }
              speech.errorListener = (error) {
                // Handle speech recognition errors
                if (error.permanent) {
                  // Handle permanent errors
                  print("Permanent error occurred: ${error.errorMsg}");
                  // If error_no_match occurs, ask again for the category
                  if (error.errorMsg == "error_no_match") {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>BottomNavController(),));
                  }
                } else {
                  // Handle non-permanent errors
                  print("Temporary error occurred: ${error.errorMsg}");
                  // You might want to retry the operation or notify the user accordingly
                }
              };
            },
          );
        }
      },
    );
  }

  void speakSelectedProductDetails() async {
    // Speak the selected product details
    await flutterTts.speak("Selected Product Details:");
    await flutterTts.speak("Product Name: ${widget.product["product-name"]}");
    await flutterTts.speak("Product Description: ${widget.product["product-description"]}");
    await flutterTts.speak("Product Price: ${widget.product["product-price"]} birr");
    await flutterTts.speak("Selected Color: $_selectedColor");
    await flutterTts.speak("Selected Size: $_selectedSize");
    await flutterTts.speak("Would you like to add this product to the cart?");
    startListening();
  }
  void checkIfFavorite() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection("users-favourite-items")
        .doc(currentUser!.email) // Use email of current user
        .collection("items")
        .doc(widget.product['product-name'])
        .get();

    setState(() {
      _isFavorite = docSnapshot.exists;
    });
  }

  void _incrementAmount() {
    setState(() {
      _selectedAmount++;
    });
  }

  void _decrementAmount() {
    if (_selectedAmount > 1) {
      setState(() {
        _selectedAmount--;
      });
    }
  }

  double getTotalPrice() {
    return (_selectedAmount * widget.product['product-price']).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.deep_orange,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Colors.deepOrange,
              child: IconButton(
                onPressed: () => _toggleFavorite(),
                icon: _isFavorite
                    ? Icon(
                        Icons.favorite,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.favorite_outline,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 160,
                child: Image.network(
                  widget.product['product-img'][_selectedImageIndex],
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 5),
              Container(
                height: 75,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.product['product-img'].length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.product['product-img'][index],
                              ),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedImageIndex == index
                                ? Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Text(
                widget.product['product-name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.product['product-description'] ?? "",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10),
              Text(
                " ${getTotalPrice().toStringAsFixed(2)} birr",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.red),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Color:",
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: _buildColorOptions(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Size:",
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: _buildSizeOptions(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Amount:",
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: _decrementAmount,
                      ),
                      Text(
                        _selectedAmount.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _incrementAmount,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(),
              SizedBox(
                width: 1.sw,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    addToCart();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Cart(),
                    ),
                    );
                  },
                  child: Text(
                    "Add to cart",
                    style: TextStyle(color: Colors.white, fontSize: 18.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep_orange,
                    elevation: 3,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: isListening ? stopListening : _startListening,
                    color: isListening ? Colors.red : Colors.grey,
                  ),
                  SizedBox(width: 10),
                  Text(
                    isListening ? 'Listening...' : 'Tap to Speak',
                    style: TextStyle(
                      fontSize: 16,
                      color: isListening ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> addToCart() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;
    CollectionReference _collectionRef =
        FirebaseFirestore.instance.collection("users-cart-items");

    QuerySnapshot existingProducts = await _collectionRef
        .doc(currentUser!.email)
        .collection("items")
        .where("name", isEqualTo: widget.product['product-name'])
        .get();

    if (existingProducts.docs.isNotEmpty) {
      await flutterTts.speak("This product is already in your cart.");
      await flutterTts.speak("would you go to cart page");
      _startListening();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "This product is already in your cart.",
          style: TextStyle(fontSize: 20.0),
        ),
      ));
      return;
    }

    double totalPrice = getTotalPrice(); // Calculate total price here

    await _collectionRef
        .doc(currentUser.email) // Use user's email as document ID
        .collection("items")
        .doc() // Automatically generate a unique ID for the cart item
        .set({
      "name": widget.product["product-name"],
      "price": totalPrice, // Use updated total price here
      "image": widget.product["product-img"][0],
      "description": widget.product["product-description"],
      "color": _selectedColor,
      "size": _selectedSize,
    });
    await flutterTts.speak("Added to cart successfully!");
    await flutterTts.speak("go cart page?!");
    _startListening();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      content: Text(
        "Added to cart successfully!",
        style: TextStyle(fontSize: 20.0),
      ),
    ));
  }

  void _toggleFavorite() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;
    CollectionReference _collectionRef =
        FirebaseFirestore.instance.collection("users-favourite-items");

    if (_isFavorite) {
      await _collectionRef
          .doc(currentUser!.email)
          .collection("items")
          .doc(widget.product['product-name'])
          .delete();
      setState(() {
        _isFavorite = false;
      });
      await flutterTts.speak("Removed from favorites.");
      _startListening();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Removed from favorites.",
          style: TextStyle(fontSize: 20.0),
        ),
      ));
    } else {
      await _collectionRef
          .doc(currentUser!.email)
          .collection("items")
          .doc(widget.product['product-name'])
          .set({
        "name": widget.product["product-name"],
        "price": getTotalPrice(),
        "image": widget.product["product-img"][0], // Store the image URL
        // Add any other details you want to store for the favorite item
      });
      setState(() {
        _isFavorite = true;
      });
      await flutterTts.speak("Added to favorites.");
      await flutterTts.speak(" would you want see favorite page?");
      _startListening();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "Added to favorites.",
          style: TextStyle(fontSize: 20.0),
        ),
      ));
    }
  }

  Map<String, Color> colorMap = {
    'red': Colors.red,
    'blue': Colors.blue,
    'white': Colors.white,
    'black': Colors.black,
  };

  List<Widget> _buildColorOptions() {
    List<Widget> colorOptions = [];
    if (widget.product['colors'] != null &&
        widget.product['colors'] is List<dynamic>) {
      List<dynamic> colors = widget.product['colors'];
      for (var colorName in colors) {
        Color colorValue = colorMap[colorName] ?? Colors.black;
        colorOptions.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = colorName;
                });
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == colorName
                        ? Colors.green
                        : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: colorValue,
                ),
              ),
            ),
          ),
        );
      }
    }
    return colorOptions;
  }

  List<Widget> _buildSizeOptions() {
    List<Widget> sizeOptions = [];
    if (widget.product['sizes'] != null &&
        widget.product['sizes'] is List<dynamic>) {
      List<dynamic> sizes = widget.product['sizes'];
      for (var size in sizes) {
        sizeOptions.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSize = size;
                });
              },
              child: Chip(
                label: Text(
                  size,
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: _selectedSize == size
                    ? AppColors.deep_orange.withOpacity(0.5)
                    : AppColors.deep_orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: _selectedSize == size
                      ? BorderSide(color: Colors.green, width: 3)
                      : BorderSide.none,
                ),
              ),
            ),
          ),
        );
      }
    }
    return sizeOptions;
  }
}
