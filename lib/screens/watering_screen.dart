import 'package:flutter/material.dart';
import '../api/api_service.dart';

class WateringScreen extends StatefulWidget {
  @override
  _WateringScreenState createState() => _WateringScreenState();
}

class _WateringScreenState extends State<WateringScreen> {
  final ApiService _apiService = ApiService();
  String wateringStatus = "OFF";

  @override
  void initState() {
    super.initState();
    _fetchWateringStatus();
  }

  Future<void> _fetchWateringStatus() async {
    final status = await _apiService.getDeviceStatus("watering");
    setState(() {
      wateringStatus = status ?? "OFF";
    });
  }

  Future<void> _toggleWatering() async {
    final newState = wateringStatus == "ON" ? "OFF" : "ON";
    final success = await _apiService.controlDevice("watering", newState);
    if (success) {
      setState(() {
        wateringStatus = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Watering Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Watering is $wateringStatus"),
            Switch(
              value: wateringStatus == "ON",
              onChanged: (value) => _toggleWatering(),
            ),
          ],
        ),
      ),
    );
  }
}
