import 'package:flutter/material.dart';
import 'fire_screen.dart';
import 'home_screen.dart';
import 'light_screen.dart';
import 'water_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Default to HomeScreen

  final List<Widget> _pages = [
    FireScreen(),
    LightScreen(),
    HomeScreen(),
    WaterScreen(),
    SettingsScreen(), // Settings screen does not require additional parameters
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2; // Home screen index
          });
        },
        backgroundColor: _currentIndex == 2 ? Colors.blue : Colors.grey,
        child: Icon(Icons.home, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.local_fire_department,
                color: _currentIndex == 0 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _onTabTapped(0),
            ),
            IconButton(
              icon: Icon(
                Icons.lightbulb,
                color: _currentIndex == 1 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _onTabTapped(1),
            ),
            SizedBox(width: 48), // Space for the FloatingActionButton
            IconButton(
              icon: Icon(
                Icons.water,
                color: _currentIndex == 3 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _onTabTapped(3),
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: _currentIndex == 4 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _onTabTapped(4),
            ),
          ],
        ),
      ),
    );
  }
}
