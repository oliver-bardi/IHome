import 'package:flutter/material.dart';
import '../api/api_service.dart';

class HeatingScreen extends StatefulWidget {
  @override
  _HeatingScreenState createState() => _HeatingScreenState();
}

class _HeatingScreenState extends State<HeatingScreen> {
  final ApiService _apiService = ApiService();
  String _status = "unknown";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _apiService.getDeviceStatus("heating");
      setState(() {
        _status = status;
      });
    } catch (e) {
      print("Error fetching status: $e");
    }
  }

  Future<void> _controlDevice(String state) async {
    try {
      await _apiService.controlDevice("heating", state);
      _fetchStatus();
    } catch (e) {
      print("Error controlling device: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heating Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Heating Status: $_status',
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
