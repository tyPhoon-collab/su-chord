import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'theme.dart';
import 'widgets/home.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Chord',
      theme: theme,
      darkTheme: darkTheme,
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const HomePage(),
      builder: EasyLoading.init(),
      // home: const TestPage(),
    );
  }
}
