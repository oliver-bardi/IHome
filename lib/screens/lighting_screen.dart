import 'package:flutter/material.dart';
import '../api/api_service.dart';

class LightingScreen extends StatefulWidget {
  @override
  _LightingScreenState createState() => _LightingScreenState();
}

class _LightingScreenState extends State<LightingScreen> {
  final ApiService _apiService = ApiService();
  String _status = "unknown";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _apiService.getDeviceStatus("lighting");
      setState(() {
        _status = status;
      });
    } catch (e) {
      print("Error fetching status: $e");
    }
  }

  Future<void> _controlDevice(String state) async {
    try {
      await _apiService.controlDevice("lighting", state);
      _fetchStatus();
    } catch (e) {
      print("Error controlling device: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lighting Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Lighting Status: $_status',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _controlDevice("on"),
              child: Text("Turn On"),
            ),
            ElevatedButton(
              onPressed: () => _controlDevice("off"),
              child: Text("Turn Off"),
            ),
          ],
        ),
      ),
    );
  }
}
