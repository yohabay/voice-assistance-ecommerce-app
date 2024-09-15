import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/const/AppColors.dart';
import 'package:flutter_ecommerce/ui/login_screen.dart';
import 'package:flutter_ecommerce/ui/user_form.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  bool isListening = false;
  bool emailCompleted = false;
  bool passwordCompleted = false;

  @override
  void initState() {
    stopListening();
    super.initState();
    startRegistration();
  }

  startRegistration() async {
     await Future.delayed(Duration(seconds: 1)); // Delay for better UI experience
     await speak("Welcome back to Registration page.");
     await Future.delayed(Duration(seconds: 1));
     askForEmail();
  }
 gotologinPage()async{
    await speak("Would you have account?");
    startListening();
    await speak("Let's go to login Page");
    stopListening();
 }
  signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text);
      var authCredential = userCredential.user;
      print(authCredential!.uid);
      if (authCredential.uid.isNotEmpty) {
        Navigator.pushReplacement(
          context,

          CupertinoPageRoute(
            builder: (_) => UserForm(user: authCredential),
          ),
        );
        stopListening();
        enableSpeech = false;
      }

      else {
        speak('Something is wrong maybe the connection is gone');
        Fluttertoast.showToast(msg: "Something is wrong");
      }
    }
    on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        await speak("The password provided is too weak please try to say strong password at list six character.");
        Fluttertoast.showToast(msg: "The password provided is too weak.");
        _passwordController.clear();
        askForPassword(); // Prompt again for password
      } else if (e.code == 'email-already-in-use') {
        await speak("The account already exists for that email.");
        _emailController.clear();
        _passwordController.clear();
        Fluttertoast.showToast(
            msg: "The account already exists for that email?");
        gotologinPage(); // Prompt again for email
        startListening();
      }
    } catch (e) {
      print(e);
    }
  }

  // Define a method to start listening for voice input
  bool enableSpeech = true;
  startListening() {
    if (!enableSpeech) return;
    speech.listen(
      onResult: (result) {
        String text = result.recognizedWords.replaceAll(RegExp(r'\s+'), '');
        setState(() {

          if (result.finalResult) {
            isListening = false;
            if (!emailCompleted) {
              _emailController.text = text.trim()+"@gmail.com"; // Fill in email field
              emailCompleted = true;
              askForPassword();
            } else if (!passwordCompleted) {
              _passwordController.text = text.trim(); // Fill in password field
              passwordCompleted = true;
              signUp(); // Attempt sign-up after password input
            }
          }
          else if (text.toLowerCase() == 'refresh' ||
              text.toLowerCase() == 'clean' ||
              text.toLowerCase() == 'reload') {
            // Refresh the page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (BuildContext context) => RegistrationScreen()),
            );
            return;
          }
          else if(text=="yes"){
            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
            stopListening();
          }
        });
      },
    );
    speech.errorListener = (error)async {
      if (error.permanent) {
        if (error.errorMsg == "error_no_match") {
          await flutterTts.speak("Sorry I don't understand");
          stopListening();
          startRegistration();
        }
      } else {
        print("Temporary error occurred: ${error.errorMsg}");
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
  speak(String message) async {
    await flutterTts.speak(message);
  }

  askForEmail() async {// Delay for better UI experience
    await speak("Please say your email address without @gmail.com.");
    startListening();
  }

  askForPassword() async {
    await Future.delayed(Duration(seconds: 1)); // Delay for better UI experience
    await speak("Please say your password.");
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
                      "Sign Up",
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
                              MaterialPageRoute(builder: (BuildContext context) => RegistrationScreen()),
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
                          "Welcome Buddy!",
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
                                  hintText: "thed9954@gmail.com",
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
                        SizedBox(
                          width: 1.sw,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: () {
                              signUp();
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
                        SizedBox(
                          height: 20.h,
                        ),
                        Wrap(
                          children: [
                            Text(
                              "Do you have an account?",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBBBBBB),
                              ),
                            ),
                            GestureDetector(
                              child: Text(
                                " Sign In",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deep_orange,
                                ),
                              ),
                              onTap: () {
                                Navigator.pushReplacement(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => LoginScreen()));
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
