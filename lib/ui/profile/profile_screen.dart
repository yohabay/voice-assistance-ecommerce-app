import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/ui/bottom_nav_pages/profile.dart';
import 'package:flutter_ecommerce/ui/login_screen.dart';
import 'package:flutter_ecommerce/ui/profile/components/paymentform.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'components/profile_menu.dart';
import 'components/profile_pic.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ProfileScreen extends StatefulWidget {
  static String routeName = "/profile";

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakWelcomeMessage();
    _listen();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords.toLowerCase();
            _handleVoiceCommand(_text);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _handleVoiceCommand(String command) {
    switch (command) {
      case 'welcome':
        _speakWelcomeMessage();
        break;
      case 'profile information':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(),
          ),
        );
        break;
      case 'saved payment methods':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentForm(),
          ),
        );
        break;
      case 'log out':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _speakWelcomeMessage() async {
    await flutterTts.speak('Welcome to your profile. You have the following options:');
    await flutterTts.speak('Personal Information, Saved Payment Methods, or Log Out.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            onPressed: _listen,
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const ProfilePic(),
            ProfileMenu(
              text: "Personal Information",
              icon: Icons.person,
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(),
                  ),
                );
              },
            ),
            ProfileMenu(
              text: "Saved Payment Methods",
              icon: Icons.credit_card,
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentForm(),
                  ),
                );
              },
            ),
            ProfileMenu(
              text: "Log Out",
              icon: Icons.logout,
              press: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
