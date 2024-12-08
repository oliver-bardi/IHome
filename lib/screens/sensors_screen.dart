import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({Key? key}) : super(key: key);

  @override
  _SensorsScreenState createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  List<dynamic> sensors = [];

  Future<void> fetchSensors() async {
    final url = Uri.parse('http://192.168.137.1:5000/sensors');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        sensors = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba: ${response.body}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSensors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Szenzoradatok')),
      body: ListView.builder(
        itemCount: sensors.length,
        itemBuilder: (context, index) {
          final sensor = sensors[index];
          return ListTile(
            title: Text(sensor['name']),
            subtitle: Text('Hőmérséklet: ${sensor['temperature']}°C\n'
                'Páratartalom: ${sensor['humidity']}%'),
            trailing: Text(sensor['timestamp']),
          );
        },
      ),
    );
  }
}
