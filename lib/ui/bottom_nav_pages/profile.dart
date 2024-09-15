import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/const/AppColors.dart';
import 'package:flutter_ecommerce/ui/profile/components/profile_pic.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController? _nameController;
  TextEditingController? _phoneController;
  TextEditingController? _ageController;

  bool _isEditing = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakProfileInformation();
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
      case 'profile information':
        _speakProfileInformation();
        break;
      case 'update name':
        _updateProfileField('name');
        break;
      case 'update phone':
        _updateProfileField('phone');
        break;
      case 'update age':
        _updateProfileField('age');
        break;
      default:
        break;
    }
  }

  void _updateProfileField(String field) {
    flutterTts.speak('Please say the new $field');
    _speech.listen(
      onResult: (val) => setState(() {
        switch (field) {
          case 'name':
            _nameController!.text = val.recognizedWords;
            break;
          case 'phone':
            _phoneController!.text = val.recognizedWords;
            break;
          case 'age':
            _ageController!.text = val.recognizedWords;
            break;
          default:
            break;
        }
      }),
    );
  }


  Future<void> _speakProfileInformation() async {
    await flutterTts.speak('Your name is ${_nameController!.text}, your phone number is ${_phoneController!.text}, and your age is ${_ageController!.text}');
    await flutterTts.speak('Do you want to update your profile?');
    _listen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("users-form-data")
                .doc(FirebaseAuth.instance.currentUser!.email)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              var data = snapshot.data;
              if (data == null) {
                return Center(child: CircularProgressIndicator());
              }
              _nameController = TextEditingController(text: data['name']);
              _phoneController = TextEditingController(text: data['phone']);
              _ageController = TextEditingController(text: data['age']);
              if (!_isEditing) {
                return showUserData(data);
              } else {
                return editUserData(data);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget showUserData(data) {
    return Column(
      children: [
        const ProfilePic(),
        Container(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${data['name']}',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      'Phone: ${data['phone']}',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      'Age: ${data['age']}',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Text('Edit', style: TextStyle(color: Colors.white, fontSize: 18.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep_orange,
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget editUserData(data) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(labelText: 'Phone'),
        ),
        TextFormField(
          controller: _ageController,
          decoration: InputDecoration(labelText: 'Age'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isEditing = false;
              updateData();
            });
          },
          child: Text('Update'),
        ),
      ],
    );
  }

  void updateData() {
    CollectionReference _collectionRef =
    FirebaseFirestore.instance.collection("users-form-data");
    _collectionRef.doc(FirebaseAuth.instance.currentUser!.email).update({
      "name": _nameController!.text,
      "phone": _phoneController!.text,
      "age": _ageController!.text,
    }).then((value) => print("Updated Successfully"));
  }
}

class UpdateProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
      body: Center(
        child: Text('Update Profile Page'),
      ),
    );
  }
}
