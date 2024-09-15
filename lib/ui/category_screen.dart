import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/ui/product_details_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';


class Categories extends StatefulWidget {
  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final List<Category> categories = [
    Category(name: 'clothes', image: 'assets/icons/jacket.png'),
    Category(name: 'shoes', image: 'assets/icons/shoes.png'),
    Category(name: 'electronics', image: 'assets/icons/electronics.png'),
    Category(name: 'cosmetics', image: 'assets/icons/cosmetics.png'),
    Category(name: 'jewelry', image: 'assets/icons/jewelry.pngs'),
  ];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  void fetchCategories() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('category').get();

      List<String> categoryNames =
      querySnapshot.docs.map((doc) => doc.id).toList();

      List<Category> fetchedCategories = categories
          .where((category) => categoryNames.contains(category.name))
          .toList();

      setState(() {
        categories.clear();
        categories.addAll(fetchedCategories);
      });
    } catch (error) {
      print('Error fetching categories: $error');
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(category: categories[index]);
      },
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to ProductsPage with the selected category
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage(category: category.name,),));

      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            radius: 30,
            backgroundImage: AssetImage(category.image),
          ),
          SizedBox(height: 10),
          Text(
            category.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class Category {
  final String name;
  final String image;

  Category({required this.name, required this.image});
}

class ProductsPage extends StatefulWidget {
  final String category;

  ProductsPage({required this.category});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _fetchProductsFuture;
  late List<String> _subcategories;
  late String _selectedSubcategory; // Added variable to store selected subcategory
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _subcategories = [];
    _fetchProductsFuture = fetchProducts(widget.category, ''); // Initialize with empty subcategory
    fetchSubcategories(widget.category);
    _selectedSubcategory = ''; // Initialize selected subcategory
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _speakWelcome();
    _listenForSubcategory();
  }

  Future<void> fetchSubcategories(String category) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('category').doc(category).get();
      if (doc.exists) {
        setState(() {
          _subcategories = List<String>.from(doc['subCategory']);
        });
      } else {
        print('Document does not exist');
      }
    } catch (error) {
      print('Error fetching subcategories: $error');
    }
  }
  Future<List<Product>> fetchProducts(String category, String subcategory) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .where('subcategory', isEqualTo: subcategory) // Filter by subcategory
          .get();

      List<Product> products = querySnapshot.docs.map((doc) {
        var images = doc['product-img'];
        List<String> imageUrl = [];

        if (images is List<dynamic> && images.isNotEmpty) {
          imageUrl = List<String>.from(images.map((image) => image.toString()));
        } else if (images is String) {
          imageUrl = [images];
        }

        return Product(
          name: doc['product-name'],
          description: doc['product-description'],
          price: doc['product-price'].toDouble(),
          image: imageUrl,
          colors: List<String>.from(doc['colors']),
          sizes: List<String>.from(doc['sizes']),
        );
      }).toList();

      return products;
    } catch (error) {
      print('Error fetching products: $error');
      throw error;
    }
  }

  void _speakWelcome() async {
    await _flutterTts.speak('Welcome to the ${widget.category} products page.');
    _speakSubcategories();
  }

  void _speakSubcategories() async {
    await _flutterTts.speak('Here are the available subcategories:');
    for (var subcategory in _subcategories) {
      await _flutterTts.speak(subcategory);
    }
    await _flutterTts.speak("which one provided for you?");
    _listenForSubcategory();
  }

  void _listenForSubcategory() async {
    if (await _speech.initialize()) {
      await _speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String spokenText = result.recognizedWords.toLowerCase();
            // Handle variations of "tishurt" and "shirt"
            if (spokenText == "tishurt" || spokenText == "tish" || spokenText == "t_shurt") {
              spokenText = "tishurt";
            } else if (spokenText == "shirt" || spokenText == "shurt" || spokenText == "sh") {
              spokenText = "shirt";
            }
            if (_subcategories.contains(spokenText)) {
              setState(() {
                _selectedSubcategory = spokenText;
                _fetchProductsFuture = fetchProducts(widget.category, _selectedSubcategory);
              });
              await _flutterTts.speak('Fetching products in $_selectedSubcategory.');
              _speakProducts();
            }
            else {
              await _flutterTts.speak('Subcategory not found. Please choose a valid subcategory.');
              _listenForSubcategory(); // Listen again for valid subcategory
            }
          }
        },
      );
    } else {
      await _flutterTts.speak('Speech recognition not available.');
    }
    _speech.errorListener = (error) {
      // Handle speech recognition errors
      if (error.permanent) {
        // Handle permanent errors
        print("Permanent error occurred: ${error.errorMsg}");
        // If error_no_match occurs, ask again for the category
        if (error.errorMsg == "error_no_match") {
          _speakSubcategories();
        }
      } else {
        // Handle non-permanent errors
        print("Temporary error occurred: ${error.errorMsg}");
        // You might want to retry the operation or notify the user accordingly
      }
    };
  }

  void _speakProducts() async {
    List<Product> products = await _fetchProductsFuture;
    if (products.isNotEmpty) {
      int currentIndex = 0;
      bool speakingProducts = true;

      // Speak the initial message
      await _flutterTts.speak('Here are the products in $_selectedSubcategory:');
      await speakProductDetails(products[currentIndex]);

      // Listen for voice commands
      while (speakingProducts) {
        await _speech.listen(
          onResult: (result) async {
            if (result.finalResult) {
              String spokenText = result.recognizedWords.toLowerCase();
              if (spokenText == 'next' && currentIndex < products.length - 1) {
                currentIndex++;
                await speakProductDetails(products[currentIndex]);
              } else if (spokenText == 'back' && currentIndex > 0) {
                currentIndex--;
                await speakProductDetails(products[currentIndex]);
              } else if (spokenText == 'detail') {
                // Navigate to product details page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetails(products[currentIndex].toMap()),
                  ),
                );
                // Stop speaking products
                speakingProducts = false;
              }
            }
          },
        );
      }
    } else {
      await _flutterTts.speak('No products found in $_selectedSubcategory.');
      _speakSubcategories();
    }
  }

// Function to speak the details of a single product
  Future<void> speakProductDetails(Product product) async {
    String productDetails = '${product.name}. '
        'Price: ${product.price.toStringAsFixed(2)} birr. '
        'Color: ${product.colors.join(", ")}. '
        'Size: ${product.sizes.join(", ")}. '
        'Description: ${product.description ?? "Not available"}.';

    await _flutterTts.speak(productDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products - ${widget.category}'),

      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);

            },
            icon: Icon(
              Icons.refresh,
              color: Colors.blue, // Change the color of the icon
              size: 30, // Change the size of the icon
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Subcategories:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _subcategories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubcategory = _subcategories[index]; // Update selected subcategory
                      _fetchProductsFuture = fetchProducts(widget.category, _selectedSubcategory); // Fetch products for selected subcategory
                      _speakProducts();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedSubcategory == _subcategories[index] ? Colors.blue : Colors.grey, // Highlight selected subcategory
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _subcategories[index],
                        style: TextStyle(
                          color: _selectedSubcategory == _subcategories[index] ? Colors.white : Colors.black, // Adjust text color based on selection
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: _fetchProductsFuture,
              builder: (context, AsyncSnapshot<List<Product>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<Product> products = snapshot.data ?? [];
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75, // Aspect ratio for each grid item
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Navigate to product details page with the selected product
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetails(products[index].toMap()), // Passing product details as a Map
                            ),
                          );
                        },

                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 150, // Set desired height for the image container
                                width: double.infinity, // Take full width
                                child: Image.network(
                                  products[index].image[0], // Display the first image of the product
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                products[index].name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${products[index].price.toStringAsFixed(2)} birr',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),

                            ],
                          ),
                        ),

                      );
                    },

                  );
                }
              },
            ),
          ),

          Container(
            alignment: Alignment.bottomRight,
            margin: EdgeInsets.only(right: 50.0),
            child: BottomAppBar(
              color: Colors.transparent, // Set the color of the BottomAppBar
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Add some padding for spacing
                child: IconButton(
                  icon: Icon(Icons.mic),
                  onPressed: () {
                    _listenForSubcategory();
                  },
                  color: Colors.blue, // Set the color of the icon
                  iconSize: 32, // Set the size of the icon
                ),
              ),
            ),
          ),
        ],

      ),

    );
  }
}

class Product {
  final String name;
  final double price;
  final description;
  final List<String> image;
  final List<String> colors;
  final List<String> sizes;

  Product({
    required this.name,
    required this.price,
    required this.image,
    required this.colors,
    required this.sizes,
    this.description,
  });

  // Method to convert Product object into a Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'product-name': name,
      'product-price': price,
      'product-description': description,
      'product-img': image,
      'colors': colors,
      'sizes': sizes,
      // Convert image URL into a list for consistency with existing code
      // Add other fields if needed
    };
  }
}
