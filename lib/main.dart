import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP csomag importálása
import 'dart:convert'; // JSON dekódolás

class ESP32ControlScreen extends StatefulWidget {
  @override
  _ESP32ControlScreenState createState() => _ESP32ControlScreenState();
}

class _ESP32ControlScreenState extends State<ESP32ControlScreen> {
  Map<String, dynamic> esp32Data = {};
  bool isLoading = false;

  Future<void> fetchESP32Status() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Feltételezve, hogy helyes URL-t használsz a backendhez
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/status'));
      if (response.statusCode == 200) {
        setState(() {
          esp32Data = json.decode(response.body);
          print("ESP32 Data: $esp32Data");
        });
      } else {
        print("Failed to load status data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching ESP32 status: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final switchStates = (esp32Data['data']?['switchStates'] ?? {}) as Map<dynamic, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32 Control"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Temperature 1: ${esp32Data['data']?['temperature1'] ?? 'N/A'} °C"),
          Text("Humidity 1: ${esp32Data['data']?['humidity1'] ?? 'N/A'} %"),
          Text("Temperature 2: ${esp32Data['data']?['temperature2'] ?? 'N/A'} °C"),
          Text("Humidity 2: ${esp32Data['data']?['humidity2'] ?? 'N/A'} %"),
          Text("Switch States:"),
          for (var entry in switchStates.entries)
            Text("Switch ${entry.key}: ${entry.value}"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchESP32Status,
            child: Text("Refresh Status"),
          ),
        ],
      ),
    );
  }
}
