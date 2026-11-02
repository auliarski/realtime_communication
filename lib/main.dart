
import 'package:flutter/material.dart';

import 'praktikum/praktikum1.dart';
import 'praktikum/praktikum2.dart';
import 'praktikum/praktikum3.dart';
import 'praktikum/praktikum4.dart';

void main() {
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
          praktikButton(
            context,
            'Praktikum 1 - REST API',
            const Praktikum1(),
          ),
          praktikButton(
            context,
            'Praktikum 2 - Polling',
            const Praktikum2(),
          ),
          praktikButton(
            context,
            'Praktikum 3 - SSE',
            const Praktikum3(),
          ),
          praktikButton(
            context,
            'Praktikum 4 - WebSocket',
            const Praktikum4(),
          ),
        ],
      ),
    );
  }

  Widget praktikButton(
    BuildContext context,
    String title,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Text(title),
        ),
      ),
    );
  }
}
