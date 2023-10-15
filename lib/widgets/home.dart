import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'config_view.dart';
import 'pages/realtime_estimator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(title: const Text('Chord')),
        drawer: const _HomeDrawer(),
        body: Column(
          children: [
            const ConfigView(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: DefaultTextStyle.merge(
                  style:
                  TextStyle(color: Get.theme.colorScheme.onSurfaceVariant),
                  child: const EstimatorPage(),
                ),
              ),
            ),
          ],
        ),
      );
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(child: Text('Chord')),
          AboutListTile(icon: Icon(Icons.library_books_outlined)),
        ],
      ),
    );
  }
}
