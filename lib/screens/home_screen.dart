import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Az aktuálisan kiválasztott lap indexe

  // Oldalak listája
  final List<Widget> _pages = [
    Center(child: Text('Kezdőlap', style: TextStyle(fontSize: 24))),
    Center(child: Text('Tűz', style: TextStyle(fontSize: 24))),
    Center(child: Text('Villanykörte', style: TextStyle(fontSize: 24))),
    Center(child: Text('Víz', style: TextStyle(fontSize: 24))),
    Center(child: Text('Beállítások', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Megjelenítjük az aktuális oldalt
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.local_fire_department, color: _currentIndex == 1 ? Colors.blue : Colors.grey),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.lightbulb, color: _currentIndex == 2 ? Colors.blue : Colors.grey),
              onPressed: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
            SizedBox(width: 48), // Középső ikon helye
            IconButton(
              icon: Icon(Icons.water_drop, color: _currentIndex == 3 ? Colors.blue : Colors.grey),
              onPressed: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: _currentIndex == 4 ? Colors.blue : Colors.grey), // Fogaskerék ikon
              onPressed: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 0; // Középső ikon (Kezdőlap) kiválasztása
          });
        },
        child: Icon(Icons.home, size: 32), // Középső kezdőlap ikon
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
