import 'package:flutter/material.dart';
import '../api/api_service.dart';

class HeatingScreen extends StatefulWidget {
  @override
  _HeatingScreenState createState() => _HeatingScreenState();
}

class _HeatingScreenState extends State<HeatingScreen> {
  final ApiService _apiService = ApiService();
  double temperature1 = 0.0;
  double humidity1 = 0.0;
  double temperature2 = 0.0;
  double humidity2 = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  Future<void> _fetchSensorData() async {
    final data = await _apiService.getSensorData();
    if (data != null) {
      setState(() {
        temperature1 = data['temperature1'] ?? 0.0;
        humidity1 = data['humidity1'] ?? 0.0;
        temperature2 = data['temperature2'] ?? 0.0;
        humidity2 = data['humidity2'] ?? 0.0;
      });
    } else {
      // Kezelheted, ha az adatok nullak, például egy hibaüzenetet jeleníthetsz meg
      print("Failed to load sensor data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Heating Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Temperature 1: $temperature1 °C"),
            Text("Humidity 1: $humidity1 %"),
            Text("Temperature 2: $temperature2 °C"),
            Text("Humidity 2: $humidity2 %"),
          ],
        ),
      ),
    );
  }
}
