import 'package:flutter/material.dart';
import '../api/api_service.dart';

class LightingScreen extends StatefulWidget {
  @override
  _LightingScreenState createState() => _LightingScreenState();
}

class _LightingScreenState extends State<LightingScreen> {
  final ApiService _apiService = ApiService();
  Map<int, String> switchStatuses = {};

  @override
  void initState() {
    super.initState();
    _initializeSwitchStatuses();
    _fetchAllSwitchStatuses();
  }

  // Alapértelmezett értékekkel töltsük fel a kapcsoló állapotokat, hogy mindig legyen 15 kapcsoló
  void _initializeSwitchStatuses() {
    for (int i = 0; i < 15; i++) {
      switchStatuses[i] = "OFF"; // Kezdő állapot: "OFF" minden kapcsolóhoz
    }
  }

  Future<void> _fetchAllSwitchStatuses() async {
    final statuses = await _apiService.getAllSwitchStatuses();
    setState(() {
      if (statuses != null) {
        switchStatuses.addAll(statuses);
      }
    });
  }

  Future<void> _toggleSwitch(int switchIndex) async {
    final currentState = switchStatuses[switchIndex] ?? "OFF";
    final newState = currentState == "ON" ? "OFF" : "ON";
    final success = await _apiService.controlSwitch(switchIndex, newState);
    if (success) {
      setState(() {
        switchStatuses[switchIndex] = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lighting Control")),
      body: ListView.builder(
        itemCount: switchStatuses.length,
        itemBuilder: (context, index) {
          final switchIndex = index;
          final status = switchStatuses[switchIndex] ?? "OFF";
          return ListTile(
            title: Text("Switch $switchIndex"),
            trailing: Switch(
              value: status == "ON",
              onChanged: (value) => _toggleSwitch(switchIndex),
            ),
          );
        },
      ),
    );
  }
}
