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
  int _currentIndex = 2; // Default screen: HomeScreen
  bool _isLoading = false; // Indicates if data fetching is ongoing

  final List<Widget> _pages = [
    FireScreen(),
    LightScreen(),
    HomeScreen(),
    WaterScreen(),
    SettingsScreen(),
  ];

  Map<String, ValueNotifier<Map<String, dynamic>>> roomData = {
    'Living Room': ValueNotifier({'temperature': 'N/A', 'humidity': 'N/A', 'switch': false}),
    'Bedroom': ValueNotifier({'temperature': 'N/A', 'humidity': 'N/A', 'switch': false}),
  };

  @override
  void initState() {
    super.initState();
    _initializeAppState(); // Initialize switch states and sensor data
  }

  void _initializeAppState() async {
    await _fetchSwitchStates(); // Fetch initial switch states
    _startUpdatingData(); // Start automatic data refresh
  }

  void _startUpdatingData() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchRoomData();
    });
  }

  Future<void> _fetchRoomData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.137.1:5000/sensors');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> sensors = jsonDecode(response.body);

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

  Future<void> _fetchSwitchStates() async {
    final url = Uri.parse('http://192.168.137.1:5000/switch_states');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> switchStates = jsonDecode(response.body);

        setState(() {
          roomData['Living Room']!.value = {
            ...roomData['Living Room']!.value,
            'switch': switchStates['1'] == 'ON',
          };
          roomData['Bedroom']!.value = {
            ...roomData['Bedroom']!.value,
            'switch': switchStates['2'] == 'ON',
          };
        });
      } else {
        print('Failed to fetch switch states. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching switch states: $e');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thermostat, size: 25, color: Colors.blue),
                SizedBox(height: 4),
                Text(roomName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Temp: $temperature°C', style: TextStyle(fontSize: 10)),
                Text('Humidity: $humidity%', style: TextStyle(fontSize: 10)),
                SizedBox(height: 4),
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
              Text('Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_isLoading) CircularProgressIndicator(),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3, // Display elements in three columns
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 0.8, // Adjust width/height ratio
            padding: const EdgeInsets.all(12),
            children: [
              _buildRoomCard('Living Room'),
              _buildRoomCard('Bedroom'),
              _buildEmptyWidget('Empty Widget 1'),
              _buildEmptyWidget('Empty Widget 2'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget(String label) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Center(
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
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
            _currentIndex = 2;
          });
        },
        backgroundColor: _currentIndex == 2 ? Colors.blue : Colors.grey,
        child: Icon(Icons.home, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.local_fire_department, color: _currentIndex == 0 ? Colors.blue : Colors.grey),
              onPressed: () => _onTabTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.lightbulb, color: _currentIndex == 1 ? Colors.blue : Colors.grey),
              onPressed: () => _onTabTapped(1),
            ),
            SizedBox(width: 40),
            IconButton(
              icon: Icon(Icons.water, color: _currentIndex == 3 ? Colors.blue : Colors.grey),
              onPressed: () => _onTabTapped(3),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: _currentIndex == 4 ? Colors.blue : Colors.grey),
              onPressed: () => _onTabTapped(4),
            ),
          ],
        ),
      ),
    );
  }
}
