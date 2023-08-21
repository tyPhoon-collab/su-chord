import 'package:chord/widgets/pages/home.dart';
import 'package:flutter/material.dart';

import 'service.dart';

void main() {
  register();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chord',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const HomePage(),
      // home: const TestPage(),
    );
  }
}
