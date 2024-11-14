import 'package:flutter/material.dart';
import 'screens/lighting_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Automation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LightingScreen(), // Alapértelmezett kezdőképernyő, de cserélhető
    );
  }
}
