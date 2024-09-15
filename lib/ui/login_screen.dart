import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/const/AppColors.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_controller.dart';
import 'package:flutter_ecommerce/ui/registration_screen.dart';
import 'package:flutter_ecommerce/widgets/customButton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  bool emailCompleted = false;
  bool passwordCompleted = false;
  final FlutterTts flutterTts = FlutterTts();
  @override
  void initState() {
    super.initState();
    askForEmail();
  }

  askForEmail() async {
    await speak("Ok!,Please say your email address with out @gmail.com.");
    await Future.delayed(Duration(seconds: 3));
    startListening();
  }
  gotoRegisterPage()async{
    await speak("Wouldn't have account?");
    await speak("Lets Go to Registration Page");
    startListening();
  }
  askForPassword() async {
    await Future.delayed(Duration(seconds: 1)); // Delay for better UI experience
    await speak("Please say your password.");
    await Future.delayed(Duration(seconds: 2));
    startListening();
  }
  signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text);
      var authCredential = userCredential.user;
      print(authCredential!.uid);
      if (authCredential.uid.isNotEmpty) {
        await speak("Sign in successful.");
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => BottomNavController(),
          ),
        );
        enableSpeech = false;
      } else {
        await speak("Sorry, something went wrong.");
        Fluttertoast.showToast(
          msg: "Something went wrong",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    }
    on FirebaseAuthException catch (e) {
      String errorMessage = "";
      if (e.code=='user-not-found') {
         await speak("No user found for that email.");
         Fluttertoast.showToast(msg: "No user found for that email.");
         _emailController.clear();
         _passwordController.clear();
        gotoRegisterPage();
      }
       else  if (e.code=='wrong-password') {
        await speak("Wrong password provided. Please enter the correct one.");
        Fluttertoast.showToast(msg: "Wrong password provided.");
        _emailController.clear();
        _passwordController.clear();
        askForPassword();
      }
        else {
          await flutterTts.speak("Please try again?");
          _emailController.clear();
          _passwordController.clear();
        gotoRegisterPage();
      }
    }
    catch (e) {
      print(e);
    }
  }

  // Add this boolean flag
  bool enableSpeech = true;

// Update startListening method
  startListening() {
    if (!enableSpeech) return; // Check the flag

    speech.listen(
      onResult: (result) {
        String text = result.recognizedWords.replaceAll(RegExp(r'\s+'), '');
        setState(() {
          if (result.finalResult) {
            isListening = false;
            Duration(seconds: 10);
            if (!emailCompleted) {
              _emailController.text = text.trim()+'@gmail.com';
              emailCompleted = true;
              askForPassword();
            } else if (!passwordCompleted) {
              _passwordController.text = text;
              passwordCompleted = true;
              signIn();
            }
          }
          else if (text.toLowerCase() == 'refresh' ||
              text.toLowerCase() == 'clean' ||
              text.toLowerCase() == 'reload') {
            // Refresh the page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (BuildContext context) => LoginScreen()),
            );
            return;
          }
          else if(text=="yes"){
            Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen(),));
          }
          else if(text=="no"){
            askForEmail();
          }
        });
      },
    );

    speech.errorListener = (error)async {
      if (error.permanent) {
        if (error.errorMsg == "error_no_match") {
          await flutterTts.speak("Sorry I don't understand");
          stopListening();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
        }
      } else {
        print("Temporary error occurred: ${error.errorMsg}");
      }
    };

    setState(() {
      isListening = true;
    });
  }

// Update stopListening method
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


  speak(String message) async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVoice({"name": "en-us-x-sfg#male_1-local"});
    await flutterTts.speak(message);
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
                      "Sign In",
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
                              MaterialPageRoute(builder: (BuildContext context) => LoginScreen()),
                            );
                          },
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.blue, // Change the color of the icon
                            size: 30, // Change the size of the icon
                          ),
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                              fontSize: 22.sp, color: AppColors.deep_orange),
                        ),
                        Text(
                          "Glad to see you back my buddy.",
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
                              height: 48.h,
                              width: 41.w,
                              decoration: BoxDecoration(
                                  color: AppColors.deep_orange,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Center(
                                child: Icon(
                                  Icons.email_outlined,
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
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: "ab@gmail.com",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'EMAIL',
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
                              height: 48.h,
                              width: 41.w,
                              decoration: BoxDecoration(
                                  color: AppColors.deep_orange,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Center(
                                child: Icon(
                                  Icons.lock_outline,
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
                                controller: _passwordController,
                                obscureText: _obscureText,
                                decoration: InputDecoration(
                                  hintText: "password must be 6 character",
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF414041),
                                  ),
                                  labelText: 'PASSWORD',
                                  labelStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.deep_orange,
                                  ),
                                  suffixIcon: _obscureText == true
                                      ? IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = false;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        size: 20.w,
                                      ))
                                      : IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = true;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.visibility_off,
                                        size: 20.w,
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 50.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.mic),
                              onPressed: isListening ? stopListening : startListening,
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
                        customButton("Sign In", () {
                          signIn();
                        }),
                        SizedBox(
                          height: 20.h,
                        ),
                        Wrap(
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBBBBBB),
                              ),
                            ),
                            GestureDetector(
                              child: Text(
                                " Sign Up",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deep_orange,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) =>
                                            RegistrationScreen()));
                              },
                            )
                          ],
                        )
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
