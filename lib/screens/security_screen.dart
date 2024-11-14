import 'package:flutter/material.dart';
import '../api/api_service.dart';

class SecurityScreen extends StatefulWidget {
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final ApiService _apiService = ApiService();
  String _status = "unknown";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _apiService.getDeviceStatus("security");
      setState(() {
        _status = status;
      });
    } catch (e) {
      print("Error fetching status: $e");
    }
  }

  Future<void> _controlDevice(String state) async {
    try {
      await _apiService.controlDevice("security", state);
      _fetchStatus();
    } catch (e) {
      print("Error controlling device: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Security Status: $_status',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _controlDevice("arm"),
              child: Text("Arm"),
            ),
            ElevatedButton(
              onPressed: () => _controlDevice("disarm"),
              child: Text("Disarm"),
            ),
          ],
        ),
      ),
    );
  }
}
