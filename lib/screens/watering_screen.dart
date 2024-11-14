import 'package:flutter/material.dart';
import '../api/api_service.dart';

class WateringScreen extends StatefulWidget {
  @override
  _WateringScreenState createState() => _WateringScreenState();
}

class _WateringScreenState extends State<WateringScreen> {
  final ApiService _apiService = ApiService();
  String _status = "unknown";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _apiService.getDeviceStatus("watering");
      setState(() {
        _status = status;
      });
    } catch (e) {
      print("Error fetching status: $e");
    }
  }

  Future<void> _controlDevice(String state) async {
    try {
      await _apiService.controlDevice("watering", state);
      _fetchStatus();
    } catch (e) {
      print("Error controlling device: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watering Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Watering Status: $_status',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _controlDevice("start"),
              child: Text("Start"),
            ),
            ElevatedButton(
              onPressed: () => _controlDevice("stop"),
              child: Text("Stop"),
            ),
          ],
        ),
      ),
    );
  }
}
