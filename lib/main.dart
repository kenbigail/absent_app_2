import 'package:attendance_edit/ui/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyBsjp_HHEJ9QvhQtsgSvCQZVFw88VcglMQ', //current_key
          appId:
              '1:770473546013:android:6a02380b2e13d44720d1f4', //mobilesdk_app_id
          messagingSenderId: '770473546013', //project_number
          projectId: 'attendance-dce82' //project_id
          ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
