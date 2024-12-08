import 'dart:async';
import 'package:flutter/material.dart';
import 'fire_screen.dart';
import 'home_screen.dart';
import 'light_screen.dart';
import 'water_screen.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Kezdeti képernyő: HomeScreen
  bool _isLoading = false; // Jelzi, ha az adatok frissítése folyamatban van

  final List<Widget> _pages = [
    FireScreen(),
    LightScreen(),
    HomeScreen(),
    WaterScreen(),
    SettingsScreen(),
  ];

  // `ValueNotifier` használata az adatok frissítéséhez
  Map<String, ValueNotifier<Map<String, dynamic>>> roomData = {
    'Living Room': ValueNotifier({'temperature': 'N/A', 'humidity': 'N/A', 'switch': false}),
    'Bedroom': ValueNotifier({'temperature': 'N/A', 'humidity': 'N/A', 'switch': false}),
  };

  @override
  void initState() {
    super.initState();
    _startUpdatingData();
  }

  void _startUpdatingData() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchRoomData();
    });
  }

  Future<void> _fetchRoomData() async {
    if (_isLoading) return; // Ha már frissít, nem kezd új frissítést
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.137.1:5000/sensors');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> sensors = jsonDecode(response.body);

        // Frissítjük a `ValueNotifier` értékeit
        for (var sensor in sensors) {
          if (sensor['name'] == 'Sensor 1') {
            roomData['Living Room']!.value = {
              'temperature': sensor['temperature']?.toString() ?? 'N/A',
              'humidity': sensor['humidity']?.toString() ?? 'N/A',
              'switch': roomData['Living Room']!.value['switch'],
            };
          } else if (sensor['name'] == 'Sensor 2') {
            roomData['Bedroom']!.value = {
              'temperature': sensor['temperature']?.toString() ?? 'N/A',
              'humidity': sensor['humidity']?.toString() ?? 'N/A',
              'switch': roomData['Bedroom']!.value['switch'],
            };
          }
        }
      } else {
        print('Failed to fetch sensors data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch sensors data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSwitch(String roomName) async {
    final switchState = roomData[roomName]!.value['switch'];
    final switchId = roomName == 'Living Room' ? '1' : '2';

    try {
      final url = Uri.parse('http://192.168.137.1:5000/switches/$switchId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': switchState ? 'OFF' : 'ON'}),
      );

      if (response.statusCode == 200) {
        roomData[roomName]!.value = {
          ...roomData[roomName]!.value,
          'switch': !switchState,
        };
      } else {
        print('Failed to toggle switch. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling switch: $e');
    }
  }

  Widget _buildRoomCard(String roomName) {
    return ValueListenableBuilder(
      valueListenable: roomData[roomName]!,
      builder: (context, data, child) {
        final temperature = data['temperature'];
        final humidity = data['humidity'];
        final isSwitchOn = data['switch'];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thermostat,
                  size: 40,
                  color: Colors.blue,
                ),
                SizedBox(height: 8),
                Text(
                  roomName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Temp: $temperature°C'),
                Text('Humidity: $humidity%'),
                SizedBox(height: 8),
                Switch(
                  value: isSwitchOn,
                  onChanged: (_) => _toggleSwitch(roomName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rooms',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_isLoading) CircularProgressIndicator(),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            padding: const EdgeInsets.all(16),
            children: [
              _buildRoomCard('Living Room'),
              _buildRoomCard('Bedroom'),
            ],
          ),
        ),
      ],
    );
  }

  void _onTabTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      print('Invalid index: $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 2 ? _buildHomeScreen() : _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2; // Vissza a HomeScreen-re
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
            SizedBox(width: 48),
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
