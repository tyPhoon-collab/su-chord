import 'package:flutter/material.dart';

import 'estimator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chord')),
        drawer: const _HomeDrawer(),
        body: const SafeArea(child: EstimatorPage()),
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
          AboutListTile(
            icon: Icon(Icons.library_books_outlined),
            applicationLegalese: '\u{a9} 2023 Hiroaki Osawa',
            applicationVersion: '2023/11/5',
            aboutBoxChildren: [
              SizedBox(height: 24),
              Text('This app estimates chords in real time from guitar audio'),
            ],
          ),
        ],
      ),
    );
  }
}
