import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'control_screen.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Konfigurációs változók a kapcsolók ID-jéhez
final int livingRoomSwitchId = 0; // Living Room-hoz a 0-ás kapcsoló
final int livingRoomWindowsSwitchId = 1; // Living Room ablak
final int bedroomSwitchId = 2;    // Bedroom-hoz a 2-es kapcsoló
final int bedroomWindowsSwitchId = 3;   // Bedroom ablak
final int shuttersSwitchId = 4;         // Redőnyök
final int garageDoorSwitchId = 5;       // Garázsnyitó
final int powerCutSwitchId = 6;         // Összes fogyasztó lekapcsolása
final int outsideLighting = 7;         //Kültéri világítás
final int vacationModeSwitchId = 8;      // Vakáció
final int securitySystemSwitchId = 9;   // Biztonsági rendszer
final int coffeMachineId = 10;           //  Kávéföző
final int gadrenWateringId = 11;          //  Öntözés
final int carChargingId = 12;             //  Kocsi töltő
final int heatingId = 13;                 // Fűtés
final int coolingId = 14;                  // Hégkondi
final int motionDetectorsId = 15;          //  Mozgásérzékeés


Map<String, ValueNotifier<bool>> switchStates = {
  'Living Room Windows': ValueNotifier(false),
  'Bedroom Windows': ValueNotifier(false),
  'Shutters': ValueNotifier(false),
  'Garage Door': ValueNotifier(false),
  'Power Cut': ValueNotifier(false),
  'Outside Lighting': ValueNotifier(false),
  'Vacation Mode': ValueNotifier(false),
  'Security System': ValueNotifier(false),
  'Coffee Machine': ValueNotifier(false),
  'Garden Watering': ValueNotifier(false),
  'Car Charging': ValueNotifier(false),
  'Heating': ValueNotifier(false),
  'Cooling': ValueNotifier(false),
  'Motion Detectors': ValueNotifier(false),
};



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
    ControlScreen(),
    SettingsScreen(),
  ];

  Map<String, ValueNotifier<Map<String, dynamic>>> roomData = {
    'Living Room': ValueNotifier({'temperature': 'N/A', 'humidity': 'N/A', 'switch': false}),
    'Bedroom': ValueNotifier({'temperature': 'N/A', 'humidity': 'N/A', 'switch': false}),
  };

  @override
  void initState() {
    super.initState();
    _fetchSwitchStates(); // Kezdeti állapotlekérés
    _fetchWeatherData();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchSwitchStates(); // 1 másodpercenként frissítjük az állapotokat
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
        final Map<String, dynamic> states = jsonDecode(response.body);

        for (var entry in switchStates.keys) {
          int id = _getSwitchId(entry);
          switchStates[entry]!.value = states['$id'] == 'ON';
        }
      } else {
        print('Failed to fetch switch states: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching switch states: $e');
    }
  }

  int _getSwitchId(String name) {
    switch (name) {
      case 'Living Room Windows': return livingRoomWindowsSwitchId;
      case 'Bedroom Windows': return bedroomWindowsSwitchId;
      case 'Shutters': return shuttersSwitchId;
      case 'Garage Door': return garageDoorSwitchId;
      case 'Power Cut': return powerCutSwitchId;
      case 'Outside Lighting': return outsideLighting;
      case 'Vacation Mode': return vacationModeSwitchId;
      case 'Security System': return securitySystemSwitchId;
      case 'Coffee Machine': return coffeMachineId;
      case 'Garden Watering': return gadrenWateringId;
      case 'Car Charging': return carChargingId;
      case 'Heating': return heatingId;
      case 'Cooling': return coolingId;
      case 'Motion Detectors': return motionDetectorsId;
      default: return -1; // Hibakezelés
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
              icon: Icon(Icons.dashboard, color: _currentIndex == 0 ? Colors.blue : Colors.grey),
              onPressed: () => _onTabTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: _currentIndex == 1 ? Colors.blue : Colors.grey),
              onPressed: () => _onTabTapped(1), // Helyes index
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
      WeatherWidget(weatherData: weatherData), // Időjárás widget
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
    final currentState = roomData[roomName]!.value['switch'];
    final switchId = roomName == 'Living Room' ? livingRoomSwitchId : bedroomSwitchId;

    try {
      final url = Uri.parse('http://192.168.137.1:5000/switches/$switchId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': currentState ? 'OFF' : 'ON'}),
      );

      if (response.statusCode == 200) {
        // Azonnal frissítsük a lámpa állapotát
        roomData[roomName]!.value = {
          ...roomData[roomName]!.value,
          'switch': !currentState,
        };

        // Kérjünk friss adatokat a szervertől
        await _fetchSwitchStates();
      } else {
        print('Failed to toggle $roomName switch: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling $roomName switch: $e');
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
          child: Container(
            height: 290, // Fix magasság a kártya számára
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded( // Üres tér az ikon előtt
                  child: SizedBox(),
                ),
                GestureDetector(
                  onTap: () => onToggleSwitch(roomName),
                  child: Icon(
                    Icons.lightbulb,
                    size: 40,
                    color: isSwitchOn ? Colors.yellow : Colors.grey,
                  ),
                ),
                Expanded( // Üres tér az ikon után
                  child: SizedBox(),
                ),
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

class ControlWidget extends StatelessWidget {
  final Function(String) onToggle;

  const ControlWidget({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Column(
        children: [
          const ListTile(
            title: Text(
              'Smart Controls',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Manage your home devices'),
          ),
          const Divider(),
          _buildSwitchRow('Living Room Windows', Icons.window),
          _buildSwitchRow('Bedroom Windows', Icons.window),
          _buildSwitchRow('Shutters', Icons.shutter_speed),
          _buildSwitchRow('Garage Door', Icons.garage),
          _buildSwitchRow('Power Cut', Icons.power_off),
          _buildSwitchRow('Outside Lighting', Icons.lightbulb_outline),
          _buildSwitchRow('Vacation Mode', Icons.beach_access),
          _buildSwitchRow('Security System', Icons.security),
          _buildSwitchRow('Coffee Machine', Icons.coffee),
          _buildSwitchRow('Garden Watering', Icons.grass),
          _buildSwitchRow('Car Charging', Icons.electric_car),
          _buildSwitchRow('Heating', Icons.whatshot),
          _buildSwitchRow('Cooling', Icons.ac_unit),
          _buildSwitchRow('Motion Detectors', Icons.motion_photos_on),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String name, IconData icon) {
    final switchState = switchStates[name] ?? ValueNotifier(false); // Biztonságos fallback
    return ValueListenableBuilder<bool>(
      valueListenable: switchState,
      builder: (context, value, _) {
        return ListTile(
          leading: Icon(icon, size: 30, color: value ? Colors.green : Colors.grey),
          title: Text(name),
          trailing: Switch(
            value: value,
            onChanged: (bool newValue) => onToggle(name),
          ),
        );
      },
    );
  }
}


// Kapcsolók kezelése a főosztályban
Future<void> _toggleControlSwitch(String controlName) async {
  int switchId;
  switch (controlName) {
    case 'Living Room Windows':
      switchId = livingRoomWindowsSwitchId;
      break;
    case 'Bedroom Windows':
      switchId = bedroomWindowsSwitchId;
      break;
    case 'Shutters':
      switchId = shuttersSwitchId;
      break;
    case 'Garage Door':
      switchId = garageDoorSwitchId;
      break;
    case 'Power Cut':
      switchId = powerCutSwitchId;
      break;
    case 'Outside Lighting':
      switchId = outsideLighting;
      break;
    case 'Vacation Mode':
      switchId = vacationModeSwitchId;
      break;
    case 'Security System':
      switchId = securitySystemSwitchId;
      break;
    case 'Coffee Machine':
      switchId = coffeMachineId;
      break;
    case 'Garden Watering':
      switchId = gadrenWateringId;
      break;
    case 'Car Charging':
      switchId = carChargingId;
      break;
    case 'Heating':
      switchId = heatingId;
      break;
    case 'Cooling':
      switchId = coolingId;
      break;
    case 'Motion Detectors':
      switchId = motionDetectorsId;
      break;
    default:
      print('Unknown control name: $controlName');
      return;
  }

  final currentState = switchStates[controlName]!.value;
  try {
    final url = Uri.parse('http://192.168.137.1:5000/switches/$switchId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'state': currentState ? 'OFF' : 'ON'}),
    );

    if (response.statusCode == 200) {
      switchStates[controlName]!.value = !currentState;
    } else {
      print('Failed to toggle $controlName: ${response.statusCode}');
    }
  } catch (e) {
    print('Error toggling $controlName: $e');
  }
}
