import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/ui/login_screen.dart';
import 'package:flutter_ecommerce/ui/registration_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'components/splash_content.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  static String routeName = "/splash";

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  int currentPage = 1;
  bool isVoiceEnabled = true; // Track if voice is enabled or not
  List<Map<String, String>> splashData = [
    {
      "text": "Welcome to Our EchoMart platform, Let’s shop!",
      "image": "assets/images/ECHOMART.png"
    },
    {
      "text": "We help people connect with stores \naround the Globe",
      "image": "assets/images/splash_2.png"
    },
    {
      "text": "We show the easy way to shop. \nJust stay at home with us",
      "image": "assets/images/splash_3.png"
    },
  ];
  List<String> alternateMessages = [
    "Sorry, I didn't catch that. Could you please repeat?",
    "I'm sorry, I didn't understand. Can you please say yes or no?",
    "My apologies, could you repeat that again?"
  ];

  Random random = Random();

  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  late AnimationController _waveController;
  String listeningText = "Listening...";

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      // Speak the welcome message
      speakWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void speakWelcomeMessage() async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(
        "Welcome to our EchoMart platform, I Can help you to Assist How to purchase your Products efficiently!");

    // Ask the user if they have an account
    await flutterTts.speak("Would you have an account?");
    // Initialize SpeechToText instance and start listening for the user's response
    initSpeechToText();
  }
  void initSpeechToText() async {
    bool isAvailable = await speech.initialize(
      onError: (error) => print('Error: $error'),
    );

    if (isAvailable) {
      // Start listening for the user's response continuously
      speech.listen(
        onResult: (result) {
          String recognizedWords = result.recognizedWords.toLowerCase();

          if (recognizedWords.isNotEmpty) {
            // Process the recognized words
            processUserInput(recognizedWords);
          }
        },
        listenFor: Duration(seconds: 5), // Listen for 10 seconds
        partialResults: true, // Receive intermediate results
        cancelOnError: true, // Stop listening on error
      );
    } else {
      // Respond to unrecognized input
      speech.stop();
      int randomIndex = random.nextInt(alternateMessages.length);
      flutterTts.speak(alternateMessages[randomIndex]);
      // Restart speech recognition
      Duration(seconds: 2);
      speech.listen(
        onResult: (result) {
          String recognizedWords = result.recognizedWords.toLowerCase();
          if (recognizedWords.isNotEmpty) {
            // Process the recognized words
            processUserInput(recognizedWords);
          }
        },
        listenFor: Duration(seconds: 5), // Listen for 10 seconds
        partialResults: true, // Receive intermediate results
        cancelOnError: true, // Stop listening on error
      );
    }
  }


  void processUserInput(String userInput) {
    if (isVoiceEnabled) {
      if (userInput.contains('yes') || userInput.contains('have account')) {
        flutterTts.speak("Excellent! Please say your Email");
        navigateToLoginScreen();
      } else if (userInput.contains('no') || userInput.contains("don't have account")) {
        Duration(seconds: 10);
        flutterTts.speak("Don't worry! please say email address");
        navigateToRegistrationScreen();
      } else {
        // Respond to unrecognized input
        int randomIndex = random.nextInt(alternateMessages.length);
        flutterTts.speak(alternateMessages[randomIndex]);
        // Restart speech recognition
        initSpeechToText();
      }
    }
  }



  void toggleVoice() {
    setState(() {
      isVoiceEnabled = !isVoiceEnabled; // Toggle the voice status
    });
    if (!isVoiceEnabled) {
      speech.stop(); // If voice is disabled, stop listening
    }
  }

  void navigateToLoginScreen() {
    Duration(seconds: 5);
    Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  void navigateToRegistrationScreen() {
    Duration(seconds: 5);
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => RegistrationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: PageView.builder(
                  onPageChanged: (value) {
                    setState(() {
                      currentPage = value;
                    });
                  },
                  itemCount: splashData.length,
                  itemBuilder: (context, index) => SplashContent(
                    image: splashData[index]["image"]!,
                    text: splashData[index]['text']!,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          splashData.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            margin: const EdgeInsets.only(right: 5),
                            height: 6,
                            width: currentPage == index ? 20 : 6,
                            decoration: BoxDecoration(
                              color: currentPage == index
                                  ? Colors.deepOrange
                                  : const Color(0xFFD8D8D8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      Spacer(flex: 3),
                      ElevatedButton(
                        onPressed: () {
                          // Trigger voice recognition and navigation based on user's response
                          if (isVoiceEnabled) {
                            initSpeechToText();
                          } else {
                            // If voice is disabled, directly navigate to the login screen
                            navigateToLoginScreen();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                        ),
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: toggleVoice,
                        child: CustomPaint(
                          size: Size(60, 60),
                          painter: CircleVoiceAnimation(
                              isVoiceEnabled: isVoiceEnabled,
                              animationController: _waveController),
                          child: Container(
                            width: 60,
                            height: 60,
                            child: Icon(
                              Icons.mic,
                              size: 50,
                              color: isVoiceEnabled
                                  ? Colors.deepOrange
                                  : Colors.grey, // Change mic color based on voice status
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircleVoiceAnimation extends CustomPainter {
  final bool isVoiceEnabled;
  final AnimationController animationController;

  CircleVoiceAnimation({
    required this.isVoiceEnabled,
    required this.animationController,
  }) : super(repaint: animationController);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double maxRadius = size.width / 2.0;
    final double minRadius = maxRadius * 0.2;
    final double waveRadius = minRadius +
        (maxRadius - minRadius) *
            Curves.easeInOut.transform(animationController.value);

    if (isVoiceEnabled) {
      canvas.drawCircle(size.center(Offset.zero), waveRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CircleVoiceAnimation oldDelegate) =>
      isVoiceEnabled != oldDelegate.isVoiceEnabled;
}
