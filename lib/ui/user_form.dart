import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/const/AppColors.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_ecommerce/ui/registration_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
class UserForm extends StatefulWidget {
  final User? user;

  UserForm({Key? key, this.user}) : super(key: key);

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _subCityController = TextEditingController();
  TextEditingController _streetController = TextEditingController();

  TextEditingController _homeNumberController = TextEditingController();
  TextEditingController _buildingController = TextEditingController();


  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    startForm();
  }
  void dispose() {
    stopListening(); // Stop speech recognition
    flutterTts.stop(); // Stop TTS
    super.dispose();
  }

  startForm() async {
    await Future.delayed(
        Duration(seconds: 1)); // Delay for better UI experience
    await speak("Please fill out the form.");
    askForName();
  }


  Future<void> sendUserDataToDB() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    CollectionReference _collectionRef =
    FirebaseFirestore.instance.collection("users-form-data");
    return _collectionRef.doc(currentUser!.email).set({
      "name": _nameController.text,
      "phone": _phoneController.text,
      "gender": _genderController.text,
      "location": _locationController.text,
      "subCity": _subCityController.text,
      "street": _streetController.text,
      "homeNumber": _homeNumberController.text,
      "building": _buildingController.text
    }).then((value) {
      // Show snackbar if registration is successful
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Registered Successfully",
          style: TextStyle(fontSize: 20.0),
        ),
      ));
      // Navigate to the desired screen after registration
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => BottomNavController()));
    }).catchError((error) => print("something is wrong. $error"));
  }
  bool enableSpeech = true;
  final List<String> ethiopianTowns = ['Addis Ababa', 'Dire Dawa', 'Gondar', 'Mekelle', 'Adama', 'Bahir Dar', 'Hawassa'];
  final List<String> ethiopianStreets = ['Churchill Road', 'Ras Desta Damtew Street', 'Bole Road', 'Africa Avenue', 'Meskel Square'];
  final List<String> ethiopianBuildings = ['Desta Mall', 'Edna Mall', 'Dashen Bank Building', 'National Theater', 'Abyssinia Plaza'];

  startListening() {
    if (!enableSpeech) return;
    speech.listen(
      onResult: (result) {
        String text = result.recognizedWords.replaceAll(RegExp(r'\s+'), '');
        setState(() {

          if (result.finalResult) {
            isListening = false;
            // Validate and fill in the text fields based on recognized speech
            if (text.toLowerCase() == 'back') {
              // Navigate back to the sign-up page
              Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen(),));
              return;
            }
            else if (text.toLowerCase() == 'refresh' ||
                text.toLowerCase() == 'clean' ||
                text.toLowerCase() == 'reload') {
              // Refresh the page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (BuildContext context) => UserForm()),
              );
              return;
            }
            if (_nameController.text.isEmpty) {
              if (isNameValid(text.trim())) {
                _nameController.text = text.trim();
                askForPhone();
              }
              if (!isNameValid(text.trim())) {
                stopListening();
                speak("I'm sorry,");
                askForName();
              }
              else{
                speech.errorListener = (error)async {
                  // Handle speech recognition errors
                  if (error.permanent) {
                    // Handle permanent errors
                    print("Permanent error occurred: ${error.errorMsg}");
                    // If error_no_match occurs, ask again for the category
                    if (error.errorMsg == "error_no_match") {
                      await flutterTts.speak("Sorry I don't understand");
                      stopListening();
                      askForName(); // Assuming AskCategory() is a function to ask for the category again

                    }
                  } else {
                    // Handle non-permanent errors
                    print("Temporary error occurred: ${error.errorMsg}");
                    // You might want to retry the operation or notify the user accordingly
                  }
                };
            }
              }
            else if (_phoneController.text.isEmpty) {
              if (isNumeric(text)) {
                _phoneController.text = text.trim();
                askForGender();
              }
              else {
                stopListening();
                speak("Please say a valid phone number.");
                Duration(seconds: 5);
                askForPhone();
              }
            }
            else if (_genderController.text.isEmpty) {
              String genderText = text.toLowerCase();
              if (genderText.contains('male') || genderText.contains('m')|| genderText.contains('men')) {
                _genderController.text = 'male';
                askForLocation();
              } else if (genderText.contains('female') || genderText.contains('f')) {
                _genderController.text = 'female';
                askForLocation();
              } else {
                // Handle unrecognized input
                stopListening();
                speak("Please say 'male' or 'female' to specify your gender.");
                askForGender();
              }
            }

            else if (_locationController.text.isEmpty) {
            if (isLocationValid(text.trim())) {
              _locationController.text = text.trim();
              askForSubCity(); // Ask for street name after location
            }
            else{
              speech.errorListener = (error)async {
                // Handle speech recognition errors
                if (error.permanent) {
                  // Handle permanent errors
                  print("Permanent error occurred: ${error.errorMsg}");
                  // If error_no_match occurs, ask again for the category
                  if (error.errorMsg == "error_no_match") {
                    await flutterTts.speak("Sorry I don't understand");
                    stopListening();
                    askForLocation(); // Assuming AskCategory() is a function to ask for the category again

                  }
                } else {
                  // Handle non-permanent errors
                  print("Temporary error occurred: ${error.errorMsg}");
                  // You might want to retry the operation or notify the user accordingly
                }
              };
            }
            }

            else if (_subCityController.text.isEmpty) {
              if (issubCityValid(text.trim())) {
                _subCityController.text = text.trim();
                askForStreet(); // Ask for home number after street
              }
              else{
                speech.errorListener = (error)async {
                  // Handle speech recognition errors
                  if (error.permanent) {
                    // Handle permanent errors
                    print("Permanent error occurred: ${error.errorMsg}");
                    // If error_no_match occurs, ask again for the category
                    if (error.errorMsg == "error_no_match") {
                      await flutterTts.speak("Sorry I don't understand");
                      stopListening();
                      askForSubCity(); // Assuming AskCategory() is a function to ask for the category again

                    }
                  } else {
                    // Handle non-permanent errors
                    print("Temporary error occurred: ${error.errorMsg}");
                    // You might want to retry the operation or notify the user accordingly
                  }
                };
              }
            }

            else if (_streetController.text.isEmpty) {
            if (isStreetValid(text.trim())) {
              _streetController.text = text.trim();
              askForHomeNumber(); // Ask for home number after street
            }
            else{
              speech.errorListener = (error)async {
                // Handle speech recognition errors
                if (error.permanent) {
                  // Handle permanent errors
                  print("Permanent error occurred: ${error.errorMsg}");
                  // If error_no_match occurs, ask again for the category
                  if (error.errorMsg == "error_no_match") {
                    await flutterTts.speak("Sorry I don't understand");
                    stopListening();
                    askForStreet(); // Assuming AskCategory() is a function to ask for the category again

                  }
                } else {
                  // Handle non-permanent errors
                  print("Temporary error occurred: ${error.errorMsg}");
                  // You might want to retry the operation or notify the user accordingly
                }
              };
            }
            }
            else if (_homeNumberController.text.isEmpty) {
              if (isNumeric(text)) {
                _homeNumberController.text = text.trim();
                askForBuilding(); // Ask for building name after home number
              } else {
                stopListening();
                speak("Please say a valid home number.");
                askForHomeNumber();
              }
            }
            else if (_buildingController.text.isEmpty) {
              if (isBuildingValid(text.trim())) {
                _buildingController.text = text.trim();
                sendUserDataToDB();
              }
              else{
                speech.errorListener = (error)async {
                  // Handle speech recognition errors
                  if (error.permanent) {
                    // Handle permanent errors
                    print("Permanent error occurred: ${error.errorMsg}");
                    // If error_no_match occurs, ask again for the category
                    if (error.errorMsg == "error_no_match") {
                      await flutterTts.speak("Sorry I don't understand");
                      stopListening();
                      askForBuilding(); // Assuming AskCategory() is a function to ask for the category again

                    }
                  } else {
                    // Handle non-permanent errors
                    print("Temporary error occurred: ${error.errorMsg}");
                    // You might want to retry the operation or notify the user accordingly
                  }
                };
              }
            }
          }
          else {
            speech.errorListener = (error) async {
              // Handle speech recognition errors
              if (error.permanent) {
                // Handle permanent errors
                print("Permanent error occurred: ${error.errorMsg}");
                // If error_no_match occurs, ask again for the category
                if (error.errorMsg == "error_no_match") {
                  await flutterTts.speak("Sorry I don't understand");
                  stopListening();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserForm(),));
                };
              }
            };
          }
        });

      }

    );

    setState(() {
      isListening = true;
    });
  }
  bool isNameValid(String name) {
    // Name should contain only alphabets and spaces
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(name);
  }
  bool isLocationValid(String location) {
    // Location should contain only alphabets and spaces
    // return ethiopianTowns.contains(location);
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(location);
  }
  bool issubCityValid(String subCity) {
    // Location should contain only alphabets and spaces
    // return ethiopianTowns.contains(location);
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(subCity);
  }
  bool isStreetValid(String street) {
    // Street name can contain alphabets, numbers, spaces, and common punctuation
    // return ethiopianStreets.contains(street);
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(street);
  }

  bool isBuildingValid(String building) {
    // Building name/number can contain alphabets, numbers, spaces, and common punctuation
    // return ethiopianBuildings.contains(building);
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(building);
  }

  bool isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  stopListening() {
    if (!enableSpeech) {
      setState(() {
        isListening = false;
      });
      return;
    }
    speech.errorListener = (error) async {
      // Handle speech recognition errors
      if (error.permanent) {
        // Handle permanent errors
        print("Permanent error occurred: ${error.errorMsg}");
        // If error_no_match occurs, reload the page
        if (error.errorMsg == "error_no_match") {
          await flutterTts.speak("Sorry I don't understand");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (BuildContext context) => UserForm()),
          );
        }
      } else {
        // Handle non-permanent errors
        print("Temporary error occurred: ${error.errorMsg}");
      }
    };
    setState(() {
      isListening = false;
    });
  }

  speak(String message) async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(message);
  }

  askForName() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say your name.");
    startListening();
  }

  askForPhone() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say your phone number.");
    startListening();
  }

  askForDOB() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say your date of birth.");
    startListening();
  }

  askForGender() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say your gender.");
    startListening();
  }

  askForSubCity() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say your Sub city.");
    startListening();
  }
  askForLocation()async{
    await Future.delayed(Duration(seconds: 1));
    await speak("please say main known Location");
    startListening();
  }
  askForStreet() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say the street name.");
    startListening();
  }

  askForHomeNumber() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say your home number.");
    startListening();
  }

  askForBuilding() async {
    await Future.delayed(Duration(seconds: 1));
    await speak("Please say the building name.");
    startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deep_orange,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 150.h,
              width: ScreenUtil().screenWidth,
              child: Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.light,
                        color: Colors.transparent,
                      ),
                    ),
                    Text(
                      "Submit The Form To Continue",
                      style: TextStyle(fontSize: 22.sp, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: ScreenUtil().screenWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28.r),
                    topRight: Radius.circular(28.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Navigate to the desired page when the icon is clicked
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (BuildContext context) => UserForm()),
                            );
                          },
                          icon: Icon(Icons.refresh), // Use any desired icon
                        ),
                        SizedBox(
                          height: 15.h,
                        ),
                        Text(
                          "WE Will Not Share Your Information With Any one!",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                        SizedBox(
                          height: 15.h,
                        ),
                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                  color: AppColors.deep_orange,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Center(
                                child: Icon(
                                  Icons.person_2_outlined,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: "Enter Name",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Name',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.h,
                        ),

                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                  color: AppColors.deep_orange,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Center(
                                child: Icon(
                                  Icons.call_made,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  hintText: "Enter phone",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Phone',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.h,
                        ),

                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                  color: AppColors.deep_orange,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Center(
                                child: Icon(
                                  Icons.male_outlined,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _genderController,
                                decoration: InputDecoration(
                                  hintText: "Enter Gender",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Gender',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                color: AppColors.deep_orange,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: "Enter main Location",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Main Location',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.h,
                        ),

                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                  color: AppColors.deep_orange,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Center(
                                child: Icon(
                                  Icons.date_range,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _subCityController,
                                decoration: InputDecoration(
                                  hintText: "Enter subCity",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'SubCity',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                color: AppColors.deep_orange,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _streetController,
                                decoration: InputDecoration(
                                  hintText: "Enter Street Name",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Street Name',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                color: AppColors.deep_orange,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _homeNumberController,
                                decoration: InputDecoration(
                                  hintText: "Enter Home Number",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Home Number',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Container(
                              height: 36.h,
                              width: 36.w,
                              decoration: BoxDecoration(
                                color: AppColors.deep_orange,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _buildingController,
                                decoration: InputDecoration(
                                  hintText: "Enter Building Name",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'Building Name',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.mic),
                              onPressed:
                                  isListening ? stopListening : startListening,
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
                        SizedBox(
                          height: 20.h,
                        ),
                        SizedBox(
                          width: 1.sw,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: () {
                              sendUserDataToDB();
                            },
                            child: Text(
                              "Continue",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deep_orange,
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
