import 'package:flutter/material.dart';
import '../api/api_service.dart';

class SecurityScreen extends StatefulWidget {
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final ApiService _apiService = ApiService();
  String securityStatus = "OFF";

  @override
  void initState() {
    super.initState();
    _fetchSecurityStatus();
  }

  Future<void> _fetchSecurityStatus() async {
    final status = await _apiService.getDeviceStatus("security");
    setState(() {
      securityStatus = status ?? "OFF";
    });
  }

  Future<void> _toggleSecurity() async {
    final newState = securityStatus == "ON" ? "OFF" : "ON";
    final success = await _apiService.controlDevice("security", newState);
    if (success) {
      setState(() {
        securityStatus = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Security Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Security is $securityStatus"),
            Switch(
              value: securityStatus == "ON",
              onChanged: (value) => _toggleSecurity(),
            ),
          ],
        ),
      ),
    );
  }
}
