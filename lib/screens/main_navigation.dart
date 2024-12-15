import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'fire_screen.dart';
import 'home_screen.dart';
import 'light_screen.dart';
import 'water_screen.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Default screen: HomeScreen
  bool _isLoading = false; // Loading state
  Map<String, dynamic>? weatherData;

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
    _initializeAppState();
    _fetchWeatherData();
  }

  void _initializeAppState() {
    _fetchSwitchStates();
    _startUpdatingData();
  }

  void _startUpdatingData() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchRoomData();
      _fetchSwitchStates();
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

  Future<void> _fetchWeatherData() async {
    const apiKey = '53ccc9f9f08ce779ae096346f1a630c4'; // API kulcs
    const city = "Târgu Mureș";
    final Uri url = Uri.parse("https://api.openweathermap.org/data/2.5/weather?q=$city&APPID=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
        });
      } else {
        print('Failed to fetch weather data: ${response.statusCode}');
        setState(() {
          weatherData = null; // Ha nincs adat
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        weatherData = null; // Ha hiba történik
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _currentIndex == 2 ? _buildHomeScreen() : _pages[_currentIndex],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        backgroundColor: _currentIndex == 2 ? Colors.blue : Colors.grey,
        child: const Icon(Icons.home, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
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
            const SizedBox(width: 40),
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

  void _onTabTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      print('Invalid index: $index');
    }
  }

  Widget _buildHomeScreen() {
    List<Widget> widgets = [
      WeatherWidget(weatherData: weatherData), // Dinamikusan kezeli az adatokat
      //EmptyWidget(),
      RoomWidget(
        roomName: 'Living Room',
        roomData: roomData['Living Room']!,
        onToggleSwitch: _toggleSwitch,
      ),
      RoomWidget(
        roomName: 'Bedroom',
        roomData: roomData['Bedroom']!,
        onToggleSwitch: _toggleSwitch,
      ),
    ];

    return ReorderableListView(
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final Widget item = widgets.removeAt(oldIndex);
          widgets.insert(newIndex, item);
        });
      },
      children: widgets.map((widget) => Container(key: ValueKey(widget), child: widget)).toList(),
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
        await _fetchSwitchStates(); // Immediately fetch updated states
      } else {
        print('Failed to toggle switch. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling switch: $e');
    }
  }
}

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Empty Widget',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class RoomWidget extends StatelessWidget {
  final String roomName;
  final ValueNotifier<Map<String, dynamic>> roomData;
  final Function(String) onToggleSwitch;

  const RoomWidget({super.key,
    required this.roomName,
    required this.roomData,
    required this.onToggleSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: roomData,
      builder: (context, data, child) {
        final temperature = data['temperature'] ?? 'N/A';
        final humidity = data['humidity'] ?? 'N/A';
        final isSwitchOn = data['switch'] ?? false;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 10.0,
                      percent: _calculatePercent(temperature),
                      center: Text(
                        "$temperature°C",
                        style: const TextStyle(fontSize: 16),
                      ),
                      progressColor: Colors.orangeAccent,
                      backgroundColor: Colors.grey[300]!,
                    ),
                    CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 10.0,
                      percent: _calculatePercent(humidity),
                      center: Text(
                        "$humidity%",
                        style: const TextStyle(fontSize: 16),
                      ),
                      progressColor: Colors.blueAccent,
                      backgroundColor: Colors.grey[300]!,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => onToggleSwitch(roomName),
                  child: Icon(
                    Icons.lightbulb,
                    size: 40,
                    color: isSwitchOn ? Colors.yellow : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculatePercent(dynamic value) {
    if (value == 'N/A') return 0.0;
    double numericValue = double.tryParse(value.toString()) ?? 0.0;
    return (numericValue / 100).clamp(0.0, 1.0);
  }
}

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic>? weatherData;

  const WeatherWidget({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    // Ha az adatok nem érhetők el
    if (weatherData == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Weather data is not available.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Ha az adatok elérhetők
    final String location = weatherData!['name']; // Város neve
    final String description = weatherData!['weather'][0]['description'];
    final double temperature = (weatherData!['main']['temp'] as num).toDouble() - 273.15; // Kelvin -> Celsius
    final double tempMin = (weatherData!['main']['temp_min'] as num).toDouble() - 273.15;
    final double tempMax = (weatherData!['main']['temp_max'] as num).toDouble() - 273.15;
    final double humidity = (weatherData!['main']['humidity'] as num).toDouble(); // Always cast as double
    final double windSpeed = (weatherData!['wind']['speed'] as num).toDouble();
    final double pressure = (weatherData!['main']['pressure'] as num).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Helyiség neve (pl. város)
            Text(
              location,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Fő cím
            const Text(
              'Weather Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Időjárás leírása
            Text(
              'The weather is $description.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Hőmérséklet, páratartalom és szélsebesség kördiagramok
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularIndicator(
                  value: temperature / 50, // Hőmérséklet max 50°C feltételezve
                  label: '${temperature.toStringAsFixed(1)}°C',
                  title: 'Temp',
                  progressColor: Colors.orange,
                ),
                _buildCircularIndicator(
                  value: humidity / 100, // Páratartalom max 100%
                  label: '$humidity%',
                  title: 'Humidity',
                  progressColor: Colors.blue,
                ),
                _buildCircularIndicator(
                  value: windSpeed / 20, // Szélsebesség max 20 m/s feltételezve
                  label: '${windSpeed.toStringAsFixed(1)} m/s',
                  title: 'Wind',
                  progressColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // További részletek
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Min Temp: ${tempMin.toStringAsFixed(1)}°C'),
                Text('Max Temp: ${tempMax.toStringAsFixed(1)}°C'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Pressure: $pressure hPa'),
                Text('Wind: ${windSpeed.toStringAsFixed(1)} m/s'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create a circular indicator
  Widget _buildCircularIndicator({
    required double value,
    required String label,
    required String title,
    required Color progressColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularPercentIndicator(
          radius: 50.0, // Kisebb méret
          lineWidth: 8.0,
          percent: value.clamp(0.0, 1.0), // Clamp az érték helyes határok között tartására
          center: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          progressColor: progressColor,
          backgroundColor: Colors.grey[300]!,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}