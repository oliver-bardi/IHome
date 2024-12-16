import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bejelentkezés és Regisztráció',
      theme: ThemeData(primarySwatch: Colors.blue),

      // A kezdő képernyő
      initialRoute: '/login',

      // Az alkalmazásban elérhető útvonalak
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
