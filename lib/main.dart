import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'firebase_messaging_service.dart';

import 'praktikum/praktikum1.dart';
import 'praktikum/praktikum2.dart';
import 'praktikum/praktikum3.dart';
import 'praktikum/praktikum4.dart';
import 'praktikum/praktikum5.dart';
import 'praktikum/praktikum6.dart';
import 'praktikum/praktikum7.dart';
import 'praktikum/praktikum8.dart';

// Inisialisasi Firebase dan background handler
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrasi handler notifikasi background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessagingService.instance.initializeForegroundNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Realtime Communication',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Communication'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          praktikButton(context, 'Praktikum 1 - REST API', const Praktikum1()),
          praktikButton(context, 'Praktikum 2 - Polling', const Praktikum2()),
          praktikButton(context, 'Praktikum 3 - SSE', const Praktikum3()),
          praktikButton(context, 'Praktikum 4 - WebSocket', const Praktikum4()),
          praktikButton(context, 'Praktikum 5 - MQTT', const Praktikum5()),
          praktikButton(context, 'Praktikum 6 - WebRTC', const Praktikum6()),
          praktikButton(context, 'Praktikum 7 - gRPC', const Praktikum7()),
          praktikButton(
            context,
            'Praktikum 8 - Firebase Cloud Messaging',
            const Praktikum8(),
          ),
        ],
      ),
    );
  }

  Widget praktikButton(BuildContext context, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Padding(padding: const EdgeInsets.all(15), child: Text(title)),
      ),
    );
  }
}
