import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/ui/splash/splash_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter E-Commerce',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: SplashScreen(),
        );
      },
    );


  }
}
// class VoiceModelService {
//   static final _instance = VoiceModelService._internal();
//   factory VoiceModelService() => _instance;
//   VoiceModelService._internal();
//
//   Future<void> loadModel() async {
//     await Tflite.loadModel(
//       model: "assets/model.tflite",
//     );
//   }
//
//   Future<List<dynamic>> runInference(List<double> input) async {
//     return await Tflite.runModelOnBuffer(
//       buffer: input,
//       numThreads: 1,
//       asynch: true,
//     );
//   }
// }